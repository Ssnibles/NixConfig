# =============================================================================
# Example devenv.nix Modular Configuration
# =============================================================================
# Use this file as a template when setting up a new project with devenv!
# Documentation & options reference: https://devenv.sh/reference/options/
# =============================================================================
{ pkgs, lib, config, inputs, ... }:

{
  # ── Environment Variables ──────────────────────────────────────────────────
  env = {
    APP_ENV = "development";
    PORT = "8080";
    # DATABASE_URL = "postgres://postgres:postgres@localhost:5432/myapp_dev";
  };

  # ── Package Toolchain ──────────────────────────────────────────────────────
  # Extra CLI tools needed in the shell (beyond language defaults)
  packages = with pkgs; [
    git
    curl
    jq
    ripgrep
    fd
  ];

  # ── Language Toolchains & Frameworks ───────────────────────────────────────
  # Enable language support out-of-the-box with managed toolchains & LSPs:

  # Rust
  languages.rust = {
    enable = true;
    channel = "stable"; # "stable", "nightly", or custom overlay
    components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" ];
  };

  # TypeScript / Node.js
  # languages.typescript.enable = true;
  # languages.javascript = {
  #   enable = true;
  #   package = pkgs.nodejs_22;
  #   npm.enable = true;
  #   pnpm.enable = true;
  # };

  # Python
  # languages.python = {
  #   enable = true;
  #   venv.enable = true;
  #   poetry.enable = true;
  #   uv.enable = true;
  # };

  # Go
  # languages.go = {
  #   enable = true;
  # };

  # Nix formatting & LSP support
  languages.nix.enable = true;

  # ── Background Services (Orchestrated in Dev Shell) ───────────────────────
  # Services start automatically with `devenv up` or process manager:

  # PostgreSQL
  # services.postgres = {
  #   enable = true;
  #   package = pkgs.postgresql_16;
  #   initialDatabases = [ { name = "myapp_dev"; } ];
  #   listen_addresses = "127.0.0.1";
  #   port = 5432;
  # };

  # Redis
  # services.redis = {
  #   enable = true;
  #   port = 6379;
  # };

  # ── Pre-commit Git Hooks ───────────────────────────────────────────────────
  # Automatically runs formatters and linters on `git commit`
  pre-commit.hooks = {
    # Nix formatter
    nixfmt-rfc-style.enable = true;

    # Rust linter & formatter
    clippy.enable = true;
    rustfmt.enable = true;

    # Shell script checker
    shellcheck.enable = true;

    # Trailing whitespace check
    trailing-whitespace.enable = true;
  };

  # ── Custom Shell Scripts & Tasks ───────────────────────────────────────────
  # Define project-specific CLI shortcuts (`devenv run <script>` or directly in shell)
  scripts = {
    dev.exec = ''
      echo "Starting development server..."
      # cargo watch -x run
      # npm run dev
    '';

    db-reset.exec = ''
      echo "Resetting database..."
      # devenv tasks run db:reset
    '';
  };

  # ── Shell Entry Hook ───────────────────────────────────────────────────────
  enterShell = ''
    echo "=================================================="
    echo "🚀 Developer Environment Activated!"
    echo "  - Rust version: $(rustc --version)"
    echo "  - Nixfmt enabled for formatting"
    echo "  - Run 'devenv up' to start background services"
    echo "=================================================="
  '';
}
