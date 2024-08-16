{
  description = "Simon Shine's Nix templates";

  outputs = { self }: {
    templates = {
      rust-simple = {
        path = ./rust-simple;
        description = "A simple Rust flake";
      };
    };
  };
}
