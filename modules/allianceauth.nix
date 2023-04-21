{ config, lib, pkgs, ... }:
let
  allianceauth = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "allianceauth"
    version = "1.2.3";

    src = pkgs.python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "something";
    };

    doCheck = false; # What does this mean?
    # propogatedBuildInputs = with pkgs.python3.pkgs [ six django_appconf ] # Some example of pulling in dependencies?
  };

  djangoEnv = pkgs.python3.withPackages (ps: with ps; [
    wheel
    gunicorn
    allianceauth
  ]);
in {

}
