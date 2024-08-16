# Simon's Nix flake templates

These are project templates for demonstrating development environments with Nix.

You can use `nix flake init` to get started, using e.g.:

```
mkdir hello-rs
cd hello-rs
nix flake init --template github:sshine/templates#rust-simple
```

But they are mainly intended for reading flake.nix for inspiration.

## [rust-simple](./rust-simple)

Provide a devShell with the Rust toolchain, nothing else.

You need to `cargo build`, `cargo run`, etc.

The flake does not export any packages.
