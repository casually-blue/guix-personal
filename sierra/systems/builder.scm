(define-module (sierra systems builder)
               #:use-module (guix transformations)

               #:use-module (gnu)

               #:use-module (nongnu system linux-initrd)

               #:use-module (gnu services networking)
               #:use-module (gnu services ssh)
               #:use-module (gnu services linux)
               #:use-module (gnu services desktop)

               #:use-module (gnu packages screen)
               #:use-module (gnu packages ssh)
               #:use-module (gnu packages vim)
               #:use-module (gnu packages shells)
               #:use-module (nongnu packages nvidia)

               #:use-module (nongnu packages linux)
               #:use-module (gnu packages linux)

               #:export (sierra-os-builder))


(define* (make-services use-nvidia)
         (append (if use-nvidia
                   (list (simple-service
                           'custom-udev-rules udev-service-type
                           (list nvidia-driver))
                         (service kernel-module-loader-service-type
                                  '("ipmi_devintf"
                                    "nvidia"
                                    "nvidia_modeset"
                                    "nvidia_uvm")))
                   (cons))
                 (list (service dhcp-client-service-type)
                       (service gnome-desktop-service-type)
                       (set-xorg-configuration
                         (xorg-configuration
                           (modules (append (if use-nvidia nvidia-driver cons) %default-xorg-modules))
                           (drivers (if use-nvidia '("nvidia") '()))
                           (keyboard-layout (keyboard-layout "us" "altgr-intl")))))
                 %base-services
                 ))

(define* (sierra-os-builder
           #:key hostname file-sys needed-packages use-nvidia nonfree-firmware)
         (operating-system
           (host-name hostname)
           (timezone "America/Chicago")
           (locale "en_US.utf8")

           (kernel (if nonfree-firmware
                     linux
                     linux-libre))

           (kernel-loadable-modules (if use-nvidia (list nvidia-driver) cons))

           (kernel-arguments (append (if use-nvidia
                                       '("modprobe.blacklist=nouveau")
                                       '("")) %default-kernel-arguments))

           (initrd (if nonfree-firmware microcode-initrd base-initrd))


           (firmware (if nonfree-firmware (list linux-firmware) %base-firmware))

           (file-systems (append file-sys %base-file-systems))

           (bootloader (bootloader-configuration (bootloader grub-bootloader)))

           (users (append (list (user-account
                                  (name "admin")
                                  (group "users")
                                  (supplementary-groups '("wheel" "netdev"
                                                          "audio" "video"))))
                          %base-user-accounts))

           ;; Globally-installed packages.
           (packages (append needed-packages %base-packages))

           (services (make-services use-nvidia))))
