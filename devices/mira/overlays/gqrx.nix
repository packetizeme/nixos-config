self: super: {
  gqrx = super.gqrx.overrideAttrs (oldAttrs: rec {
    buildInputs = oldAttrs.buildInputs ++ [ super.uhd ];
  });
}
