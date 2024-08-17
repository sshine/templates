{
  description = "Simon Shine's Nix templates";

  outputs = { self }: {
    templates = {
      rust-simple = {
        path = ./rust-simple;
        description = "A simple Rust flake with a devShell";
      };

      rust-package = {
        path = ./rust-package;
        description = "A simple Rust flake with a devShell and package";
      };
    };
  };
}
