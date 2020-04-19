{ writeScriptBin, emacsPackagesNgGen, emacs, ... }:
let
  customEmacsPackages = emacsPackagesNgGen (emacs.override {
    withX = false;
    withGTK3 = false;
    withXwidgets = false;
  });
  emacs-with-packages = customEmacsPackages.emacsWithPackages (epkgs: [
    epkgs.org-plus-contrib
    epkgs.ox-hugo
  ]);
  ox-blorf = writeScriptBin "ox-blorf" ''
    export HUGO_DEFAULT_FILE="$1"
    export HUGO_BASE_DIR="$2"
    ${emacs-with-packages}/bin/emacs -Q --batch --load ${./ox-blorf.el}
  '';
in ox-blorf
