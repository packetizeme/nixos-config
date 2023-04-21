{ lib
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, scdoc
, which
}:

rustPlatform.buildRustPackage rec {
  pname = "phetch";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "xvxx";
    repo = pname;
    rev = "v${version}";

    sha256 = "sha256-rUcc0OH8M0GhwqgyqTQsti8d9qTu+rnROrgrXKPCWAs=";
  };

  cargoPatches = [
    ./10-update-cargo-lock.patch # Fixes building openssl-sys
  ];

  cargoSha256 = "sha256-zITqk6HfY123p2EEnA0vpXnhopHcUj67T974mSQtM3o=";

  nativeBuildInputs = [ pkg-config scdoc which ];
  buildInputs = [ openssl ];

  postInstall = ''
    make manual
    mkdir -p $out $man/share/man/man1
    install -m644 doc/phetch.1 $man/share/man/man1
  '';

  doCheck = false;

  outputs = [ "out" "man" ];

  meta = with lib; {
    description = "A quick lil gopher client for your terminal, written in rust";
    longDescription = ''
      phetch is a terminal client designed to help you quickly navigate the gophersphere.
      - <1MB executable for Linux, Mac, and NetBSD
      - Technicolor design (based on GILD)
      - No-nonsense keyboard navigation
      - Supports Gopher searches, text and menu pages, and downloads
      - Save your favorite Gopher sites with bookmarks
      - Opt-in history tracking
      - Secure Gopher support (TLS)
      - Tor support
    '';

    changelog = "https://github.com/xvxx/phetch/releases/tag/v${version}";
    homepage = "https://github.com/xvxx/phetch";
    license = "licenses.mit";
    maintainers = with maintainers; [ felixalbrigtsen ];
  };
}
