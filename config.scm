;; This is an operating system configuration template
;; for a "desktop" setup with GNOME and Xfce where the
;; root partition is encrypted with LUKS, and a swap file.

(use-modules 
  (gnu) 
  (gnu system nss) 
  (gnu packages vim)
  (gnu packages cups)
  (gnu packages compression)
  (gnu services cups)
  (guix utils)
  (nongnu packages linux)
  (nongnu system linux-initrd))

(use-service-modules desktop sddm xorg)
(use-package-modules certs gnome)

(define %base-system-services (append (list (service gnome-desktop-service-type)
                          (service xfce-desktop-service-type)
                          (set-xorg-configuration
                           (xorg-configuration
                            (keyboard-layout (keyboard-layout "us" "altgr-intl"))))
			  (service cups-service-type
         (cups-configuration
           (web-interface? #t)
           (extensions
             (list cups-filters epson-inkjet-printer-escpr hplip-minimal)))))
 
                    %desktop-services))

(define %my-services
  ;; My very own list of services.
  (modify-services %base-system-services
    (guix-service-type config =>
                       (guix-configuration
                        (inherit config)
                        ;; Fetch substitutes from example.org.
                        (substitute-urls
			  (append (list "https://substitutes.nonguix.org") %default-substitute-urls))
			(authorized-keys
			  (append (list (local-file "./signing-key.pub")) %default-authorized-guix-keys))))))

(operating-system
  (host-name "antelope")
  (timezone "America/Chicago")
  (locale "en_US.utf8")

  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware amdgpu-firmware))
  (kernel-arguments `("nvme_core.default_ps_max_latency_us=0 quiet nomodeset"))

  (keyboard-layout (keyboard-layout "us" "altgr-intl"))

  ;; Use the UEFI variant of GRUB with the EFI System
  ;; Partition mounted on /boot/efi.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))
                (keyboard-layout keyboard-layout)))


  (file-systems (append
                 (list (file-system
                         (device (uuid "baf7f560-5e2a-4cd2-9d04-722fbf4131dc"))
                         (mount-point "/")
                         (type "ext4"))
                       (file-system
                         (device (uuid "6076-9A65" 'fat))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems))

  ;; Create user `bob' with `alice' as its initial password.
  (users (cons (user-account
                (name "admin")
                (group "admin")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  ;; Add the `students' group
  (groups (cons* (user-group
                  (name "admin"))
                 %base-groups))

  ;; This is where we specify system-wide packages.
  (packages (append (list
                     ;; for HTTPS access
                     nss-certs
                     ;; for user mounts
                     gvfs
		     neovim
		     gzip
		     )
                    %base-packages))

  ;; Add GNOME and Xfce---we can choose at the log-in screen
  ;; by clicking the gear.  Use the "desktop" services, which
  ;; include the X11 log-in service, networking with
  ;; NetworkManager, and more.
  (services %my-services)
  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))

