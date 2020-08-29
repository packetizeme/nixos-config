{
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  name = "sddm-lain-wired-theme";
  src = fetchFromGitHub {
    owner = "lll2yu";
    repo = "sddm-lain-wired-theme";
    rev ="6bd2074ff0c3eea7979f390ddeaa0d2b95e171b7";
    sha256 = "ab97c779f213bb56a1bc3c91997e635fb2c8fb9c061718927d154bba452b8692";
  };

  installPhase = ''
    mkdir -p $out/share/sddm/themes/lain-wired
    cp -r * $out/share/sddm/themes/lain-wired
  '';

  meta = with stdenv.lib; {
    description = "A sddm login screen inspired by 1998 anime \"Serial Experiments Lain\"";
    homepage = https://github.com/lll2yu/sddm-lain-wired-theme;
    platforms = platforms.linux;
  };
}
