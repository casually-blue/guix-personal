(define-module nerdfont)
(use-modules
  (guix download)
  (guix utils)
  (guix packages)
  (guix licenses)
  (guix build-system font))

(define (font-nerdfont-builder name version hash synopsis description)
  (package
    (name (string-append "font" "-" (string-downcase name) "-" "nerdfont" "-" "ttf"))
    (version version)
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.github.com/ryanoasis/nerd-fonts/releases/download/v" version "/" name ".zip" ))
              (sha256 (base32 hash))))

    (build-system font-build-system)
    (arguments
      `(#:phases
        (modify-phases %standard-phases
                       (add-after 'install 'install-conf
                                  (lambda* (#:key outputs #:allow-other-keys)
                                           (let ((conf-dir (string-append (assoc-ref outputs "out")
                                                                          "/share/fontconfig/conf.avail")))
                                             (copy-recursively "fontconfig" conf-dir)
                                             #t))))))
    (home-page "https://www.nerdfonts.com/")
    (synopsis synopsis)
    (description description)
    (license non-copyleft)))

(define-public font-fantasquesans-mono-nerdfont-ttf (font-nerdfont-builder
  "FantasqueSansMono"
  "2.1.0"
  "147h15k3ni0w6chxkrah2fk4klhdhq8y1d3nbx763h9ia3mnggv6"
  "Fantasque Sans Mono Nerd Font"
  "\"wibbly-wobbly handwriting-like fuzziness\", takes some inspiration from Inconsolata and Monaco"))
