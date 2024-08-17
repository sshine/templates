{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

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

          packages.default = rustPlatform.buildRustPackage {
            pname = hello-rs.package.name;
            version = hello-rs.package.version;
            src = ./hello-rs;
          };
        }
    );
}
