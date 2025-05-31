{
  description = "Rust library for tools and encodings related to SAT solving library";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    systems.url = "github:nix-systems/default";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nix-tools.url = "github:gleachkr/nix-tools";
    nix-tools.inputs.nixpkgs.follows = "nixpkgs";
    #nix-tools.inputs.rust-overlay.follows = "rust-overlay";

    nix-config.url = "github:chrjabs/nix-config";
    nix-config.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:chrjabs/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    rust-overlay,
    nix-tools,
    nix-config,
    git-hooks,
    nix-github-actions,
  }: let
    lib = nixpkgs.lib;
    forAllSystems = lib.genAttrs (import systems);
    pkgsFor = rust-overlay-fn:
      lib.genAttrs (import systems) (system: (import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay) nix-tools.overlays.default rust-overlay-fn] ++ builtins.attrValues nix-config.overlays;
      }));
    rust-toolchain-overlay = _: super: {
      rust-toolchain = super.symlinkJoin {
        name = "rust-toolchain";
        paths = [(super.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)];
        buildInputs = [super.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/cargo --set LIBCLANG_PATH ${super.libclang.lib}/lib
        '';
      };
    };
    devShellSystemRustOverlay = system: rust-overlay-fn: let
      pkgs = (pkgsFor rust-overlay-fn).${system};
      libs = with pkgs; [openssl xz bzip2];
    in
      pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} rec {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        nativeBuildInputs = with pkgs;
          [
            llvmPackages.bintools
            pkg-config
            clang
            cmake
            rust-toolchain
            cargo-rdme
            cargo-nextest
            cargo-semver-checks
            cargo-hack
            cargo-spellcheck
            cargo-llvm-cov
            (cargo-valgrind.overrideAttrs (old: rec {
              version = "2.3.1";
              src = fetchFromGitHub {
                owner = "jfrimmel";
                repo = "cargo-valgrind";
                tag = version;
                sha256 = "sha256-yUCDKklkfK+2n+THH4QlHb+FpeWfObXpmp4VozsFiUM=";
              };
            }))
            valgrind
            just
            release-plz
            jq
            maturin
            kani
            veripb
            typos
            rust-cbindgen
          ]
          ++ self.checks.${system}.pre-commit-check.enabledPackages;
        buildInputs = libs;
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        LD_LIBRARY_PATH = lib.makeLibraryPath libs;
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig/";
        VERIPB_CHECKER = lib.getExe pkgs.veripb;
      };
  in {
    devShells = forAllSystems (system: {
      default = let
        pkgs = pkgsFor.${system};
        libs = with pkgs; [openssl xz bzip2];
        git-subtree-cmd =
          pkgs.writeShellScriptBin "git-subtree"
          /*
          bash
          */
          ''
            SUBTREE="$1"
            CMD="$2"
            REF="$3"

            declare -A prefixes
            prefixes=(
              ["minisat"]="minisat/cppsrc"
              ["glucose"]="glucose/cppsrc"
              ["cadical"]="cadical/cppsrc"
              ["kissat"]="kissat/csrc"
              ["cryptominisat"]="cryptominisat/csrc"
            )

            case $CMD in
              pull)
                echo "Pulling subtree $SUBTREE from ref $REF"
                git subtree pull --prefix "''${prefixes[$SUBTREE]}" "$SUBTREE" "$REF" --squash -m "chore($SUBTREE): update subtree"
                ;;

              push)
                echo "Pushing subtree $SUBTREE to ref $REF"
                git subtree push --prefix "''${prefixes[$SUBTREE]}" "$SUBTREE" "$REF"
                ;;

              *)
                2>&1 echo "Unknown command $CMD"
                2>&1 echo "Usage: git-subtree <subtree> <command> <ref>"
            esac
          '';
        pr-merge-ff-cmd =
          pkgs.writeShellScriptBin "pr-merge-ff"
          /*
          bash
          */
          ''
            set -e

            if ! ${lib.getExe pkgs.gh} pr checks ; then
              2>&1 echo "PR checks have not (yet) passed"
              exit 1
            fi

            BASE=main
            DELETE=false

            case "$1" in
              "-d")
                DELETE=true
                ;;

              *)
                echo "setting base branch to $1"
                BASE="$1"
            esac

            BRANCH=$(git rev-parse --abbrev-ref HEAD)

            git switch "$BASE"
            git merge --ff-only "$BRANCH"

            if $DELETE ; then
              git branch -d "$BRANCH"
            fi

            git push
          '';
      in
        pkgs.mkShell.override {stdenv = pkgs.clangStdenv;} rec {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          nativeBuildInputs = with pkgs;
            [
              llvmPackages_12.bintools
              pkg-config
              clang
              cmake
              rust-toolchain
              cargo-rdme
              cargo-nextest
              release-plz
              jq
              maturin
              kani
              git-subtree-cmd
              pr-merge-ff-cmd
            ]
            ++ self.checks.${system}.pre-commit-check.enabledPackages;
          buildInputs = libs;
          LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
          LD_LIBRARY_PATH = lib.makeLibraryPath libs;
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig/";
        };
      default = devShellSystemRustOverlay system rust-toolchain-overlay;
    });

    packages = forAllSystems (system: {
      tools = (pkgsFor rust-toolchain-overlay).${system}.callPackage ./tools {};
    });

    checks = forAllSystems (system: {
      pre-commit-check = let
        pkgs = (pkgsFor rust-toolchain-overlay).${system};
      in
        git-hooks.lib.${system}.run {
          src = ./.;
          tools.cargo = pkgs.rust-toolchain;
          settings.rust.check.cargoDeps = pkgs.rustPlatform.importCargoLock {lockFile = ./Cargo.lock;};
          hooks = {
            # Rust
            cargo-check = {
              enable = true;
              args = ["--workspace"];
              extraPackages = with pkgs; [
                pkg-config
                clang
                cmake
                openssl
                libclang
              ];
            };
            rustfmt.enable = true;
            # Just hooks
            just-precommit = {
              enable = true;
              name = "just precommit";
              entry = "${lib.getExe pkgs.just} precommit";
              language = "system";
              pass_filenames = false;
            };
            just-prepush = {
              enable = true;
              name = "just prepush";
              entry = "${lib.getExe pkgs.just} prepush";
              language = "system";
              pass_filenames = false;
              stages = ["pre-push"];
            };
            # TOML
            check-toml.enable = true;
            taplo.enable = true;
            # Github actions
            actionlint.enable = true;
            check-yaml.enable = true;
            # Nix
            alejandra.enable = true;
            deadnix.enable = true;
            # Python
            black.enable = true;
            # General neatness
            check-added-large-files.enable = true;
            end-of-file-fixer = {
              enable = true;
              excludes = [".+\\.(patch|log)$" "cadical/cppsrc/.+" "kissat/csrc/.+" "cryptominisat/cppsrc/.+"];
            };
            trim-trailing-whitespace = {
              enable = true;
              excludes = [".+\\.(patch|log)$" "cadical/cppsrc/.+" "kissat/csrc/.+" "cryptominisat/cppsrc/.+"];
            };
            check-symlinks.enable = true;
            no-commit-to-branch.enable = true;
          };
        };
    });

    githubActions = nix-github-actions.lib.mkGithubMatrix {
      checks = self.checks // self.packages;
    };
  };
}
