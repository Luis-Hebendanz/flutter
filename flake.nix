{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    luispkgs.url = "github:Luis-Hebendanz/nixpkgs/luispkgs";
  };

  outputs = { self, nixpkgs, utils, naersk, luispkgs }:
    utils.lib.eachDefaultSystem (system:
      let
        luis = import luispkgs { inherit system; };
        pkgs = import nixpkgs { inherit system; };
        naersk-lib = pkgs.callPackage naersk { };
        appname = "my_app3";
        nativeDeps = with pkgs; [
            autoPatchelfHook
            pkg-config
            cmake
            clang
            ninja
        ];
        buildDeps = with pkgs; [
          at-spi2-core
          dbus
          libxkbcommon
          xorg.libXdmcp
          libdatrie
          libthai
          libsepol
          libselinux
          util-linux
          wxGTK31
          gtk3
          gtk3-x11
          pcre
          libepoxy
          lzlib
          clang
        ];
      in
      {
        # In need look into the flutter2 builder:
        # https://github.com/NixOS/nixpkgs/blob/350fd0044447ae8712392c6b212a18bdf2433e71/pkgs/build-support/flutter/default.nix
        defaultPackage = with pkgs; stdenv.mkDerivation {
          src = ./${appname};
          name = appname;
          buildInputs = buildDeps;
          nativeBuildInputs = nativeDeps;
          dontConfigure = true;
          buildPhase = ''
            flutter config --no-analytics
            export LD_LIBRARY_PATH="${libepoxy}/lib"
            flutter build linux --release
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp -R build/linux/x64/release/bundle/* $out/bin
          '';
          fixupPhase = ''
            autoPatchelf -- $out/bin
          '';
        };

        defaultApp = utils.lib.mkApp {
          drv = self.defaultPackage."${system}";
        };

        devShell = with pkgs; mkShell {
          nativeBuildInputs = nativeDeps ++ [ chromium ];
          buildInputs = buildDeps;
          LD_LIBRARY_PATH = "${libepoxy}/lib";
          shellHook = ''
          export PATH="$PATH:./bin"
          export NIX_LD=$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker);
          '';
          NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildDeps;
          CHROME_EXECUTABLE = "chromium";
        };
      });
}