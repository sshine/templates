{
  description = "A Rust WebAssembly project using nightly toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustPackage = pkgs.rust-bin.nightly.latest.default;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustPackage;
          rustc = rustPackage;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            (rustPackage.override {
              # Additional targets (current platform is implied)
              targets = ["wasm32-unknown-unknown"];
            })
            wasm-pack
            nodePackages.npm
            pkg-config
            openssl
            wasmtime # runtime executable
            wabt # wasm2wat + more
            trunk
            wasm-bindgen-cli
            esbuild
            webkitgtk

            clippy
            rust-analyzer
            cargo-workspaces
          ];
        };
      }
    );
}
