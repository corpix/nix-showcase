{ pkgs        ? import <nixpkgs> {}
, tag         ? version
, tools       ? pkgs.callPackage ./tools.nix   { inherit pkgs; }
, name
, namespace
, version
, ... }:
with builtins;
with pkgs;
with lib;
let
  contents = [
    cacert coreutils busybox
    curl iproute bashInteractive
    python38
    handbrake
    ffmpeg-full
  ]
  ++ tools.mkNss { }
  ++ tools.mkHosts { }
  ++ tools.mkUsers { users = [{ name = "nobody"; uid = 11000; gid = 11000; }]; };
  timeZone = "UTC";
in dockerTools.buildLayeredImage {
  inherit tag contents;
  name = "${namespace}/${name}";

  # https://github.com/moby/moby/blob/master/image/spec/v1.2.md
  config = {
    User = "nobody";
    Env = ["TZ=${timeZone}"];
    Entrypoint = ["/bin/bash"];
    #Expose = ["4180/tcp" "4280/tcp"];
  };
}
