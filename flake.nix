{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    blank.url = "github:divnix/blank";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.inputs.flake-compat.follows = "blank";
    git-hooks-nix.inputs.gitignore.follows = "blank";
  };

  outputs =
    inputs@{
      flake-parts,
      devshell,
      treefmt-nix,
      git-hooks-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devshell.flakeModule
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          config,
          pkgs,
          lib,
          system,
          ...
        }:
        {
          ## -------------------------------------------------------------------
          ## DEV SHELL
          ## -------------------------------------------------------------------
          devshells.default = {
            packages = with pkgs; [
              uv
              packer
              hclfmt
              sops
            ];
            env = [
              {
                name = "UV_PYTHON";
                value = lib.getExe pkgs.python3;
              }
              {
                name = "UV_PYTHON_DOWNLOADS";
                value = "never";
              }
            ];
            devshell.startup.uv.text = ''
              uv venv --allow-existing
              source .venv/bin/activate
            '';
          };

          ## -------------------------------------------------------------------
          ## PACKAGES
          ## -------------------------------------------------------------------
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          ## -------------------------------------------------------------------
          ## FORMATTER
          ## -------------------------------------------------------------------
          treefmt = {
            projectRootFile = "flake.nix";

            # nix
            programs.nixfmt.enable = true;

            # toml
            programs.taplo.enable = true;

            # hcl
            programs.hclfmt.enable = true;

            # python
            programs.ruff.check = true;
            programs.ruff.format = true;

            # shell
            programs.shfmt.enable = true;
            programs.shellcheck.enable = true;
            settings.formatter.shfmt.includes = [ ".envrc" ];
            settings.formatter.shellcheck.includes = [ ".envrc" ];

            # json, yaml, markdown
            programs.prettier.enable = true;
          };

          ## -------------------------------------------------------------------
          ## PRE-COMMIT HOOKS
          ## -------------------------------------------------------------------
          devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
          pre-commit.settings.hooks.treefmt.enable = true;
        };
    };
}
