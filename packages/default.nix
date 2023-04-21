let pkgs = import <nixpkgs> { }; in
{
  phetch = pkgs.callPackage ./phetch { };
}
