self: super:

{
 sddm = super.sddm.overrideAttrs(orig: {
   buildInputs = orig.buildInputs or [] ++ [ super.qt5.qtmultimedia ];
 });

  sddm-lain-wired-theme = self.callPackage ./sddm-lain-wired-theme { };
}
