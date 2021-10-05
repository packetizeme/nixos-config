{
  stdenv,
  fetchFromGitHub,
  SDL2,
  SDL2_net,
  libssh,
  gcc,
  libyamlcpp
}:

stdenv.mkDerivation {
  name = "etherterm";

  src = fetchFromGitHub {
    owner = "M-Griffin";
    repo = "EtherTerm";
    rev ="62ed28f08f498dee4f28e9c6b82a45edf3d9a80b";
    sha256 = "bcf801cbc59044af7f47e868d34eaee2fe77c280f009b9578feb8e3556c3f80f";
  };

  patches = [
    ./EtherTerm-make.patch
  ];

  nativeBuildInputs = [
    SDL2
    SDL2_net
    libssh
    gcc
    libyamlcpp
  ];

  #configurePhase = ''

  #'';

  buildPhase = ''
    cd linux
    make -f EtherTerm.mk
    cd ..
  '';

  
  installPhase = ''
    mkdir -p $out/bin
    cp linux/Debug/EtherTerm $out/bin/EtherTerm
    chmod +x $out/bin/EtherTerm
  '';

  meta = with stdenv.lib; {
    description = "EtherTerm (SDL2) Telnet/SSH Terminal";
    homepage = https://m-griffin.github.io/EtherTerm/;
    platforms = platforms.linux;
  };
}
