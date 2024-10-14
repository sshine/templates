{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs { inherit system overlays; };

          rustPlatform = pkgs.makeRustPlatform { };

          hello-rs = builtins.fromTOML (builtins.readFile ./hello-rs/Cargo.toml);
        in
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              clippy
              rustc
              rustfmt
              rust-analyzer
              cargo-workspaces
            ];
          };

          packages.${system}.default = rustPlatform.buildRustPackage {
            pname = hello-rs.package.name;
            version = hello-rs.package.version;
            src = ./hello-rs;
          };
        }
    );
}
