#import "@preview/touying:0.5.2": *
#import themes.stargazer: *

// aqua, default, dewdrop, metropolis, simple, stargazer, university

#show: stargazer-theme.with(
  aspect-ratio: "4-3",
  config-info(
    title: [Rust dev and build environments on Nix/NixOS],
    subtitle: [Managing a Rust toolchain with Nix and Flakes],
    author: "Simon Shine <simon@simonshine.dk>",
    date: "October 31, 2024",
    logo: grid(
      columns: 2,
      align: horizon + center,
      inset: 2pt,
      image("ferris-neutral.svg"), image("nix-snowflake-colours.svg"),
    ),
    progress-bar: true,
  ),
)

#title-slide()

// === Fork this!

// - Slides and templates are available at: #link("https://github.com/sshine/templates")

#set list(marker: image("ferris-neutral.svg", width: 18pt))
#set list(marker: image("nix-snowflake-colours.svg", width: 14pt))


== Motivation for talk

=== What

- Use Nix to build Rust programs
- Address problems of increasing complexity
- Reason about effort vs. payoff for each problem / solution

#pause

=== Why (not just stick to `rustup` and `cargo`?)

- Manage external dependencies and additional build tools
- Build projects across new machines and across time
- Build projects in a way that is reproducible and declarative
- Reuse the developers' environment in CI without Devcontainers
- Produce build artifacts (e.g. executables) that can be deployed declaratively
- Faster onboarding; have less "Works On My Machine `¯\_(ツ)_/¯`"

#pause

=== How

- Show ways to install and use a Rust toolchain on a Nix system
- Some ways are hard to find, but don't complicate things ("down payment")
- Some ways complicate things ("upkeep")

== Conclusion

=== By the end of this talk, I hope to have convinced you that...

- ... a small amount of Nix will go very far
- ... a moderate amount of Nix solves real problems
- ... a large amount of Nix is a machine that feeds itself

#pause

#h(6cm) ... but the machine is reliable, reproducible, and declarative!

== Advertisement time!

=== November 5, 2024 (Tuesday):

Rust Hack Night \#10: Rust \<3 Nix

- *What:* Workshop-style, make Nix flakes for your Rust projects
- *Where:* KEA \@ Guldbergsgade 29N, 2200 Copenhagen N

_(check the Copenhagen Rust Meetup page)_

=== December 5, 2024 (Thursday):

NixOS Install Party

- *What:* Join the federation, share and improve your configuration
- *Where:* DIKU \@ Universitetsparken 1, 2200 Copenhagen N

_(check the Greater Copenhagen NixOS Meetup page)_

== A quick poll...

#align(center, image("vulcan-salute.svg", width: 20%))

=== How many of you...

=== ... run NixOS?

=== ... run Nix on another Linux or MacOS?

=== ... have made a file ending with `.nix` for a project?

== Grug Brained Developer: How do I install Rust?

#align(center, image("grug-install-rust-1.png"))
#align(center, image("grug-install-rust-2.png"))

== Overview

=== Install a system-global Rust toolchain on NixOS #h(1cm) `┬─┬ノ( º _ ºノ)`

- Install the `rustup` package from nixpkgs

#pause

=== Install a project-specific Rust toolchain #h(0.5cm) `(/¯◡ ‿ ◡)/¯ ~ ┻━┻`

- Specify whether to run `stable` or `nightly` per project
- Specify what additional build tools should be in my `$PATH`
- Cross-compilation (PC, embedded, wasm)
- Provide a customized dev shell
- Put Nix in my CI pipeline

#pause

=== Blow the novelty budget and see what's out there #h(1cm) `┻━┻︵ \(°□°)/ ︵ ┻━┻`

- Manage crates and workspaces using Nix flakes
- Use Nix flakes to maintain dependencies between repositories
- Re-establish caching (similar to how one might fight Docker's cache)
- Declaratively manage my VSCodium and its Rust plugins

// - Targets: `x86_64`, `aarch64`, `wasm32-unknown-unknown`, `wasm32-wasip2`, ...
// - A devShell with `cargo` and `rustc`
// - Providing a package
// - Providing multiple packages, one per workspace member
// - Additional Rust targets (aarch64, wasm, embedded)
// - Compiling for Windows
// - Caching (Crane? How else?)
// - Nix and CI (GitHub Actions + what else?)

== Install a system-global Rust toolchain on NixOS

#grid(
  columns: (auto, auto),
  gutter: 30pt,
  align(left + top)[=== configuration.nix

    ```nix
    {pkgs, ...}: {
      environment.systemPackages = [
        pkgs.rustup
        pkgs.gcc
      ];
    }
    ```
  ],
  align(left + top)[
    #pause
    === command-line

    ```
    $ sudo nixos-rebuild switch
    $ rustup default stable
    $ cargo init hello-world
    $ cd hello-world
    $ cargo run
    ...
    Hello, world!
    ```
  ],
)

#pause

=== Pros and cons

- That's it; you can go back to coding Rust now!
- Actually provides: `cargo rustc rust-analyzer rustdoc rustfmt rustup ...`
- Switch between `stable` / `nightly`, multiple targets, etc. the usual way
- Need to repeat `rustup` commands on new systems: Projects don't just build
- Need to switch toolchain between projects, but we have #link(
    "https://rust-lang.github.io/rustup/overrides.html#the-toolchain-file",
  )[`rust-toolchain.toml`]

== Let's make it more realistic...

=== command-line

```
$ cargo add tokio --features=full
$ cargo add reqwest --features=json
```

#pause

=== src/main.rs

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let response = reqwest::get("https://ipinfo.io/")
        .await?
        .json::<std::collections::HashMap<String, String>>()
        .await?;
    println!("{:#?}", response);
    Ok(())
}
```

== Let's make it more realistic...

```
$ cargo build
```

#pause

```
...
error: failed to run custom build command for `openssl-sys v0.9.103`
```

#pause

```
...
The pkg-config command could not be found.

  Most likely, you need to install a pkg-config package for your OS. Try `apt install pkg-config`, or `yum install pkg-config`, or `pkg install pkg-config`, or `apk add pkgconfig` depending on your distribution.
```

#pause

```
...
Could not find directory of OpenSSL installation, and this `-sys` crate cannot proceed without this knowledge. If OpenSSL is installed and this crate had trouble finding it,  you can set the `OPENSSL_DIR` environment variable for the compilation process.

  Make sure you also have the development packages of openssl installed.
  For example, `libssl-dev` on Ubuntu or `openssl-devel` on Fedora.
...
```

== Let's make it more realistic...

=== configuration.nix

#text(16pt)[
  ```nix
  {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.rustup
      pkgs.gcc
      pkgs.pkg-config
      pkgs.openssl
    ];
  ```

  #pause

  ```nix
    environment.sessionVariables = {
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc
        pkgs.openssl.dev
      ];
    };
  }
  ```
]

#pause

=== Pros and cons

- Somewhat simple, but not simple to find or guess
- "Works On My Machine." (`configuration.nix` is your machine.)
- Doesn't scale/compose well for many projects with many dependencies
- Nix chatrooms are very unhelpful when you want to do this. Don't do this!

== A quick buzzword collection (1/2)

- *Nix*: A cross-platform package manager (`nix` and `nix-*` commands)

- *Nix:* A domain-specific, lazy, functional, dyn. typed programming language

- *Nixpkgs*: The largest, most up-to-date software distribution in the world:
  - written in the Nix language,
  - installed with the Nix package manager.

- *NixOS*: A Linux-based operating system made with Nix and Nixpkgs

== A quick buzzword collection (2/2)

- *Nix expression*: An expression in the Nix language

- *configuration.nix*:
  - NixOS is defined by a single Nix expression, often stored in this file
  - NixOS initially places this file in `/etc/nixos/configuration.nix`
  - Nix expressions allow `import` ing sub-expressions in other files

- *shell.nix*, *default.nix*, *flake.nix*:
  - Used by the Nix package manager, commited to a project repository
  - Useful for dev shells, build environments, and exporting build artifacts
  - Each of these contain a single Nix expression

- *Derivation*: A data structure that describes how to build a package. It takes inputs (dependencies), build steps, and outputs (build artifacts). A simple derivation can represent a single program, and a composite derivation can represent an entire operating system.

== Entering shell.nix

#grid(
  columns: (auto, auto),
  gutter: 30pt,
  align(left + top)[=== shell.nix

    ```nix
    let
      pkgs = import <nixpkgs> {};
    in
      pkgs.mkShell {
        packages = with pkgs; [
          rustup
          pkg-config
          openssl
        ];
      }
    ```
  ],
  align(left + top)[
    #pause
    === command-line

    ```
    $ nix-shell
    [nix-shell:~/hello-world] $ cargo run
    ...
      "ip": "91.198.204.39",
      "country": "DK",
      "city": "Copenhagen",
    ...
    ```
  ],
)

#pause

=== Pros and cons

- Automates parts of setting up the environment (gcc, environment variables)
- Is located in your project directory
- Lets you install anything from nixpkgs
- Goodbye regular shell? Ô_ô -- I want my zsh aliases back!
- What version is `<nixpkgs>`? ô_Ô -- reproducibility problems ahead

== Goodbye regular shell? Ô_ô

#pause

=== Improving on shell.nix with direnv + nix-direnv

#pause

=== Installing direnv in NixOS...
#grid(
  columns: (50%, 50%),
  gutter: 30pt,
  align(left + top)[
    === direnv.nix

    ```nix
    {pkgs, ...}: {
      environment.systemPackages = [
        pkgs.direnv
      ];

      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    }
    ```
  ],
  align(left + top)[
    #pause
    === configuration.nix
    ```nix
    {pkgs, ...}: {
      imports = [
        ./hardware-configuration.nix
        ./vscodium.nix
        ./direnv.nix
        ./zsh.nix
      ];

      # ...
    }
    ```
  ],
)

#pause

#grid(
  columns: (50%, 50%),
  gutter: 30pt,
  align(left + top)[
    === Followed by...
    #text(14pt)[
      ```
      $ sudo nixos-rebuild switch
      ```
    ]
  ],
  align(left + top)[
    #pause
    === Or, if you're not on NixOS...
    #text(14pt)[
      ```nix
      $ <apt/brew/...> install direnv
      $ echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
      ```
    ]
  ],
)

== Goodbye regular shell? Ô_ô

=== Improving on shell.nix with direnv + nix-direnv

=== And now, for enabling direnv...

#text(16pt)[
  ```
  [nix-shell:~/hello-world] $ ^D
  $ echo 'use nix' > .envrc
  $ direnv allow
  ```
  #pause
  ```
  direnv: loading ~/hello-world/.envrc
  direnv: using nix
  direnv: nix-direnv: Using cached dev shell
  direnv: export +AR +AS +CC +CONFIG_SHELL +CXX +HOST_PATH +IN_NIX_SHELL +LD +NIX_BINTOOLS +NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu +NIX_BUILD_CORES +NIX_CC +NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu +NIX_CFLAGS_COMPILE +NIX_ENFORCE_NO_NATIVE +NIX_HARDENING_ENABLE +NIX_LDFLAGS ...
  ```
  #pause
  ```
  $ cargo run
  ...
    "ip": "91.198.204.39",
    "country": "DK",
    "city": "Copenhagen",
  ...
  ```
]

=== Welcome back regular shell! ^\_^

== What version is `<nixpkgs>`? ô_Ô

#pause

=== Addressing reproducibility: shell.nix doesn't have a lock-file...

#pause

#grid(
  columns: (auto, auto),
  gutter: 30pt,
  align(left + top)[=== shell.nix

    ```nix
    let
      pkgs = import <nixpkgs> {};
    in
      pkgs.mkShell {
        packages = with pkgs; [
          rustup
          pkg-config
          openssl
        ];
      }
    ```
  ],
  align(left + top)[
    #pause
    === What this syntax means

    - `<...>` resembles `#include <stdio.h>`
    - Looks in `$NIX_PATH` ("Nix search path")
    - Looks at current Nix _channels_ installed
    - Alternative: use `builtins.fetchTarball`
  ],
)

== What version is `<nixpkgs>`? ô_Ô

=== Addressing reproducibility: shell.nix doesn't have a lock-file...

=== shell.nix
#text(16pt)[
  ```nix
  let
    # nixpkgs = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
    # nixpkgs = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.11-pre.tar.gz";
    nixpkgs = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    pkgs = import (builtins.fetchTarball nixpkgs) {};
  in
    pkgs.mkShell {
      packages = with pkgs; [
        rustup
        pkg-config
        openssl
      ];
    }
  ```
]

#pause

=== Welcome back reproducibility! ^\_^

== GitHub Actions + Nix

#pause

#grid(
  columns: (auto, auto),
  gutter: 30pt,
  align(left + top)[=== default.nix
    #text(14pt)[
      ```nix
      {pkgs ? import <nixpkgs> {}}:
      pkgs.rustPlatform.buildRustPackage {
        pname = "hello-world";
        version = "0.1.0";
        src = ./.;
        cargoHash = "sha256-fCWXZbZRVBKcr27Z8Pz+mN...";
        nativeBuildInputs = with pkgs; [
          rustc
          cargo
          pkg-config
        ];
        buildInputs = with pkgs; [
          openssl
        ];
        buildPhase = ''cargo build --release'';
        checkPhase = ''
          cargo fmt --all -- --check
          cargo build --all-targets
          cargo clippy --all-targets -- -D warnings
          cargo test --all-targets
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp target/release/hello-world $out/bin/
        '';
      }
      ```
    ]
  ],
  align(left + top)[
    #pause
    === .github/workflows/rust-nix.yaml
    #text(14pt)[
      ```nix
      name: Rust CI with Nix
      on:
        workflow_dispatch:
        pull_request:
        push:
      jobs:
        nix-build:
          runs-on: ubuntu-latest
          steps:
          - uses: actions/checkout@v4
          - uses: cachix/install-nix-action@v27
            with:
              nix_path: nixpkgs=channel:nixos-unstable
          - run: nix-build --arg doCheck true
      ```
    ]

    #pause

    === Pros and cons

    - You don't also need a shell.nix
    - Automatically handles cargo-vendor
    - Simple to maintain, so-so to discover
    - Some redundancy from Cargo.toml
    - Cargo workspace ⇒ very boilerplate
  ],
)

== A small digression about _vendoring_

=== Why complicate things with default.nix? shell.nix was working fine...
- The GitHub Action could just have used `nix-shell --run cargo ...`

#pause

=== Because of reproducible builds
- We assume unconditional internet access during build (to crates.io)
- cargo-chef: Speeds up Rust Docker builds using Docker layer caching
- cargo-vendor: Downloads all dependencies for caching or version control
- `pkgs.rustPlatform.buildRustPackage` calls cargo-vendor under the hood:
  - downloads and compiles them using a so-called _fixed-output derivation_
  - makes the current package depend on that
  - caches the result until the lockfile is bumped
  - avoids manual interaction with vendored crates

== Now that I've sold you on some complexity...

#v(0.5cm)

#align(
  center,
  text(30pt)[
    `┻━┻︵ \(°□°)/ ︵ ┻━┻`
  ],
)

== Let's get more realistic: Cargo Workspaces, cross-compilation

#set list(marker: image("ferris-neutral.svg", width: 18pt))

=== More declarative alternatives to `rustup`: overlays

- *rust-overlay*: select particular Rust version and components
- *fenix*: also bundles nightly rust-analyzer and VSCode plugin

=== Packaging Rust projects with Nix

- *buildRustPackage*: requires a `cargoHash = "sha256-..."`, boilerplate
- #strike[*cargo2nix*], #strike[*crate2nix*]: both generate a Cargo.nix file (causes git noise)
- *dream2nix*: common interface across language toolchains, didn't try it
- *naersk*: reduces boilerplate, handles Cargo.lock, incremental builds, caching
- *crane*: improves on naersk: more granular build steps, better build caching, better cross-compilation support, better support for vendored dependencies

=== Flake helper libraries

- *flake-utils*: avoids duplication for multiple architectures, very common
- *flake-parts*: similar, but also well-documented, opinionated, and versatile

== Example: A Cargo workspace for: kagi-api, kagi-cli

=== What are overlays? Specifically, rust-overlay

- An overlay { modifies, adds, overrides } packages in nixpkgs
- So: rust-overlay overrides the Rust toolchain in nixpkgs

=== flake.nix (Cargo workspace for: kagi-api, kagi-cli)

```nix

```

== Some practical examples of flake.nix

- kagi-api
- web-sys-turtles
- tauri-leptos-example

== Setting up VSCodium on NixOS

==

#align(center, text(40pt)[`¯\_(ツ)_/¯`])

An explanation of the newer alternatives to `nix-shell` #link("https://blog.ysndr.de/posts/guides/2021-12-01-nix-shells/"): `nix shell`, `nix develop`, `nix run`

// == ... Tauri + Leptos Example

// I wanted to mess around with Tauri + Leptos and found:

// #link("https://github.com/michalvavra/tauri-leptos-example")

// === Prerequisites (README.md)

// #align(center, rect[
// #set text(size: 18pt)
// ```sh
// # Tauri CLI
// cargo install --locked tauri-cli

// # Rust nightly (required by Leptos)
// rustup toolchain install nightly --allow-downgrade

// # WASM target
// rustup target add wasm32-unknown-unknown

// # Trunk WASM bundler
// cargo install --locked trunk

// # `wasm-bindgen` for Apple M1 chips (required by Trunk)
// cargo install --locked wasm-bindgen-cli

// # `esbuild` as dependency of `tauri-sys` crate (used in UI)
// npm install --global --save-exact esbuild
// ```
// ])

// == A real-world `tauri-cli`

// ```
// $ cargo install --locked tauri-cli
// ...
// Installed package `tauri-cli v1.6.2` (executable `cargo-tauri`)
// warning: be sure to add `/home/sshine/.cargo/bin` to your PATH to be able to run the installed binaries

// $ echo $PATH | grep .cargo/bin

// $ cargo tauri
// Command line interface for building Tauri apps

// Usage: cargo tauri [OPTIONS] <COMMAND>
// ...
// ```

// == A real-world `rustup toolchain` and `rustup target`

// ```
// $ rustup toolchain install nightly --allow-downgrade
// ...
// warning: failed to wrap `ld.lld`: failed to create unwrapped directory
// ...

// $ which rustc
// /nix/store/fxcqdclnd07wcmr7v2pmy7hygkhpzxfx-rust-default-1.83.0-nightly-2024-09-21/bin/rustc

// $ rustc --version
// rustc 1.83.0-nightly (da889684c 2024-09-20)

// $ rustup target add wasm32-unknown-unknown

// $ rustup show | rg -A 5 targets
// installed targets for active toolchain
// --------------------------------------

// wasm32-unknown-unknown
// x86_64-unknown-linux-gnu
// ```

// == A real-world `cargo install --locked trunk`

// ```
// $ cargo install --locked trunk
// ...
// warning: package `bytemuck v1.15.0` in Cargo.lock is yanked in registry `crates-io`, consider running without --locked
// warning: package `bytes v1.6.0` in Cargo.lock is yanked in registry `crates-io`, consider running without --locked
// warning: package `libc v0.2.154` in Cargo.lock is yanked in registry `crates-io`, consider running without --locked
// ...
//   Installing /home/sshine/.cargo/bin/trunk
//    Installed package `trunk v0.20.3` (executable `trunk`)
// warning: be sure to add `/home/sshine/.cargo/bin` to your PATH to be able to run the installed binaries

// $ which trunk
// /nix/store/m30k9x1ggw5jijkg25bpymqd2gjcmjna-trunk-0.20.3/bin/trunk
// ```

// == A real-world nitpicker

// - My system is cluttered with another tool + `PATH` extension

// Ywen @ Discord:
// The easiest way to have a full rust toolchain ready (including rust-analyzer) is just:
// nix registry add fenix github:nix-community/fenix Just once. Not needed if you installed nix via the determinate-systems installer. Check nix registry list to see if fenix is in there.
// nix shell fenix#stable.toolchain then drops you in a shell with everything. So that your IDE knows where stuff is, you just need to start it from within that shell (eg. code . with VScode), and it'll see everything in the PATH set by nix shell

// (you can choose another alias for fenix if you want it shorter)
// when a new rust version is released, you can update with nix flake update --flake fenix so stable.toolchain will point to the newly release toolchain (fenix also makes available nightly toolchains in a similar fashion)

// ayats.org

// let
//   rust-overlay = builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
//   pkgs = import <nixpkgs> {
//     overlays = [(import rust-overlay)];
//   };
//   toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
// in
//   pkgs.mkShell {
//     packages = [
//       toolchain
//     ];
//   }