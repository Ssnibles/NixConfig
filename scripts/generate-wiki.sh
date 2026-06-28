#!/usr/bin/env bash
# =============================================================================
# Wiki Generator Script
# =============================================================================
# Parses the NixOS config and regenerates data-driven wiki pages.
# Run from the repo root: bash scripts/generate-wiki.sh [wiki-path]
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI_DIR="${1:-${REPO_ROOT}/../NixConfig.wiki}"

if [[ ! -d "$WIKI_DIR" ]]; then
  echo "Wiki directory not found: $WIKI_DIR"
  echo "Usage: bash scripts/generate-wiki.sh [wiki-path]"
  exit 1
fi

echo "Generating wiki pages..."
echo "  Repo: $REPO_ROOT"
echo "  Wiki: $WIKI_DIR"
echo

trim() { sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

write_if_changed() {
  local target="$1"
  local content="$2"
  if [[ -f "$target" ]] && diff -q <(echo "$content") "$target" >/dev/null 2>&1; then
    echo "  ~ $(basename "$target") (unchanged)"
    return
  fi
  echo "$content" > "$target"
  echo "  + $(basename "$target") (updated)"
}

# =============================================================================
# 1. Flake Inputs
# =============================================================================
generate_flake_inputs() {
  local flake="$REPO_ROOT/flake.nix"
  local out

  out="# Flake Inputs

> **Auto-generated** from \`flake.nix\` by \`scripts/generate-wiki.sh\`.
> Edit the generator, not this page.

## Inputs

| Input | Source | Follows nixpkgs? |
|-------|--------|-------------------|
"

  local name="" url="" follows="No" in_block=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]{4}([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\{ ]]; then
      name="${BASH_REMATCH[1]}"
      url=""
      follows="No"
      in_block=1
    elif [[ "$line" =~ ^[[:space:]]{4}([a-zA-Z0-9_-]+)\.url[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
      name="${BASH_REMATCH[1]}"
      url="${BASH_REMATCH[2]}"
      follows="No"
      out+="| \`$name\` | \`$url\` | No |"$'\n'
    elif [[ $in_block -eq 1 ]]; then
      if [[ "$line" =~ url[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        url="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ inputs\.nixpkgs\.follows ]]; then
        follows="Yes"
      fi
      if [[ "$line" =~ ^[[:space:]]{4}\}\; ]]; then
        if [[ -n "$name" && -n "$url" ]]; then
          out+="| \`$name\` | \`$url\` | $follows |"$'\n'
        fi
        in_block=0
        name=""
        url=""
      fi
    fi
  done < "$flake"

  out+="
## Overlays

- **NUR** — community packages (\`pkgs.nur.repos.*\`)
- **Unstable** — \`pkgs.unstable.*\` for bleeding-edge packages
- **Neovim** — always uses unstable neovim
- **Zen Browser** — from external flake
- **Solaar** — Logitech device manager
"

  write_if_changed "$WIKI_DIR/Flake-Inputs.md" "$out"
}

# =============================================================================
# 2. Stylix Themes
# =============================================================================
generate_stylix_themes() {
  local themes_file="$REPO_ROOT/lib/stylix/themes.nix"
  local current_file="$REPO_ROOT/lib/stylix/current-theme.nix"
  local current_theme
  current_theme=$(tr -d '"[:space:]' < "$current_file")

  local out
  out="# Stylix Themes

> **Auto-generated** from \`lib/stylix/themes.nix\` by \`scripts/generate-wiki.sh\`.
> For the full theming guide, see [Stylix Theming](Stylix-Theming).

Current theme: **${current_theme}**

## Available Themes

| Theme | Polarity |
|-------|----------|
"

  local theme_name="" polarity=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]+\"([a-zA-Z0-9_-]+)\"[[:space:]]*=[[:space:]]*\{ ]]; then
      theme_name="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ polarity[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
      polarity="${BASH_REMATCH[1]}"
      if [[ -n "$theme_name" ]]; then
        local display="$theme_name"
        [[ "$theme_name" == "$current_theme" ]] && display="**${theme_name}** (current)"
        out+="| $display | $polarity |"$'\n'
      fi
      theme_name=""
    fi
  done < "$themes_file"

  out+="
## Switching Themes

\`\`\`bash
stylix-switch <theme-name>   # Switch and rebuild (persistent)
stylix-switch --list         # List available themes
stylix-switch --current      # Show current theme
stylix-switch --apply        # Re-apply (ephemeral, HM only)
\`\`\`

## Adding a Custom Theme

Add an entry to \`themes\` in \`lib/stylix/themes.nix\`:

\`\`\`nix
\"my-theme\" = {
  polarity = \"dark\";
  scheme = {
    scheme = \"My Theme\";
    author = \"You\";
    variant = \"dark\";
    base00 = \"0b0f14\";  # background
    # ... base01 through base0F
  };
};
\`\`\`
"

  write_if_changed "$WIKI_DIR/Stylix-Themes.md" "$out"
}

# =============================================================================
# 3. Neovim (LSP servers + formatters + plugins)
# =============================================================================
generate_neovim() {
  local lsp_file="$REPO_ROOT/modules/home/apps/nvim/nvim-src/lua/plugins/lsp.lua"
  local editor_file="$REPO_ROOT/modules/home/apps/nvim/nvim-src/lua/plugins/editor.lua"
  local registry_file="$REPO_ROOT/modules/home/apps/nvim/nvim-src/lua/plugins/registry.lua"

  local out
  out="# Neovim

Neovim uses a **hybrid approach**: [nvf](https://github.com/NotAShelf/nvf) provides the Nix-based skeleton (options, packages, plugin list), while a hand-written Lua layer handles the actual plugin configuration.

## Architecture

\`\`\`
modules/home/apps/nvim/default.nix (Nix)
  ├── nvf settings: options, extraPackages, startPlugins
  ├── Symlinks nvim-src/ → ~/.config/nvf/
  └── Writes generated/colors.lua at activation
         │
         ▼
nvim-src/init.lua (Lua entry point)
  ├── keymaps.lua          # Global keybindings
  ├── autocmds.lua         # Autocommands
  ├── diagnostics.lua      # Diagnostic display config
  ├── theme.lua            # Comprehensive highlight overrides
  ├── bootstrap.lua        # Module loader (core + deferred)
  └── plugins/             # One file per plugin/feature
\`\`\`

> **Auto-generated** data tables below. Edit \`scripts/generate-wiki.sh\` to update.

## LSP Servers

Extracted from \`plugins/lsp.lua\`:

| Server | Command |
|--------|---------|
"

  local in_table=0
  while IFS= read -r line; do
    if [[ "$line" == *"managed_servers"* ]]; then
      in_table=1
      continue
    fi
    if [[ $in_table -eq 1 ]]; then
      if [[ "$line" =~ ^\} ]]; then break; fi
      local sname scmd
      sname=$(echo "$line" | grep -oP '(?<=name = ")[^"]+' 2>/dev/null || true)
      scmd=$(echo "$line" | grep -oP '(?<=cmd = ")[^"]+' 2>/dev/null || true)
      if [[ -n "$sname" && -n "$scmd" ]]; then
        out+="| \`$sname\` | \`$scmd\` |"$'\n'
      fi
    fi
  done < "$lsp_file"

  out+=$'\n'"## Formatters (Conform)"$'\n\n'
  out+="| Filetype | Formatter |"$'\n'
  out+="|----------|-----------|"$'\n'

  local in_fmt=0
  while IFS= read -r line; do
    if [[ "$line" == *"formatters_by_ft"* ]]; then
      in_fmt=1; continue
    fi
    if [[ $in_fmt -eq 1 ]]; then
      if [[ "$line" =~ ^[[:space:]]+\}, ]]; then break; fi
      local ft fmt
      ft=$(echo "$line" | grep -oP '^\s+\K[a-z]+' 2>/dev/null || true)
      fmt=$(echo "$line" | grep -oP '"[^"]+"' 2>/dev/null | tr '\n' ', ' | sed 's/,$//;s/"//g' || true)
      if [[ -n "$ft" && -n "$fmt" ]]; then
        out+="| $ft | $fmt |"$'\n'
      fi
    fi
  done < "$editor_file"

  out+=$'\n'"## Plugin Load Order"$'\n\n'
  out+="### Core (loaded immediately)"$'\n\n'

  local section="core"
  while IFS= read -r line; do
    if [[ "$line" == *"M.deferred"* ]]; then
      section="deferred"
      out+=$'\n'"### Deferred (loaded after VimEnter)"$'\n\n'
      continue
    fi
    local plugin
    plugin=$(echo "$line" | grep -oP '"plugins\.\K[^"]+' 2>/dev/null || true)
    if [[ -n "$plugin" ]]; then
      out+="- \`$plugin\`"$'\n'
    fi
  done < "$registry_file"

  out+="
## Completion (blink.cmp)

- **Sources:** LSP, snippets, buffer, path (+ spell for markdown/text)
- **Tab behavior:** Copilot ghost → accept completion → snippet forward
- **Esc:** Cancels blink → exits insert mode in one press
- **Ghost text:** Enabled, Copilot hides when blink menu is visible
- **Cmdline completion:** Separate keymap with Tab to accept

## Copilot

- Auto-trigger with 150ms debounce
- Hides during completion menu
- \`<leader>ac\` toggles, \`<leader>ap\` opens panel
- \`<Alt+]>\` / \`<Alt+[>\` cycle suggestions

## Key Design Decisions

- **Leader:** Space, **Local leader:** Backslash
- **Relative line numbers** with \`scrolloff=999\` (cursor always centered)
- **Treesitter folds** with custom fold text
- **Zed-inspired keybindings** (Ctrl+P for files, leader+/ for grep)
- **Oil** as file explorer (buffer-based, not a sidebar tree)
- **Custom floating cmdline** (minimal, top-centered, replaces built-in cmdline)
- **Snacks** for floating terminal
- **Smart Rename** (\`<leader>cr\`): picks between LSP rename, literal project replace, or regex replace
"

  write_if_changed "$WIKI_DIR/Neovim.md" "$out"
}

# =============================================================================
# 4. Keybindings
# =============================================================================
generate_keybindings() {
  local hypr_file="$REPO_ROOT/modules/home/desktop/hyprland/default.nix"
  local nvim_keys="$REPO_ROOT/modules/home/apps/nvim/nvim-src/lua/keymaps.lua"
  local tmux_file="$REPO_ROOT/modules/home/shell/tmux.nix"

  local out
  out="# Keybindings

> **Auto-generated** from config files by \`scripts/generate-wiki.sh\`.
> Edit the generator, not this page.

## Hyprland

| Binding | Action |
|---------|--------|
"

  local in_bind=0
  while IFS= read -r line; do
    if [[ "$line" =~ bind[[:space:]]*=[[:space:]]*\[ ]]; then
      in_bind=1; continue
    fi
    if [[ $in_bind -eq 1 ]]; then
      if [[ "$line" =~ ^[[:space:]]+\] ]]; then in_bind=0; continue; fi
      # Extract quoted string content
      local bindstr
      bindstr=$(echo "$line" | grep -oP '"\K[^"]+' 2>/dev/null | head -1 || true)
      if [[ -n "$bindstr" ]]; then
        # Parse: "$mod, KEY, action, target"
        local mod key action target
        IFS=',' read -r mod key action target <<< "$bindstr"
        mod=$(echo "$mod" | trim)
        key=$(echo "$key" | trim)
        action=$(echo "$action" | trim)
        target=$(echo "$target" | trim)
        if [[ -n "$key" && -n "$action" ]]; then
          local display_key="$key"
          [[ -n "$mod" && "$mod" != "" ]] && display_key="$mod + $key"
          local display_action="$action"
          [[ -n "$target" ]] && display_action="$action $target"
          # Clean up Nix variable references
          display_action="${display_action//\$\{specialWorkspaceName\}/special}"
          display_action="${display_action//\$\{screenshotDir\}/~/Pictures/Screenshots}"
          display_action="${display_action//\$\{sattyFocusCommand\}/...}"
          display_action="${display_action//\$\{sattyCaptureCommand\}/...}"
          # Truncate very long commands
          if [[ ${#display_action} -gt 80 ]]; then
            display_action="${display_action:0:77}..."
          fi
          out+="| \`$display_key\` | $display_action |"$'\n'
        fi
      fi
    fi
  done < "$hypr_file"

  out+=$'\n'"## Neovim (Leader = Space)"$'\n\n'
  out+="| Binding | Mode | Action |"$'\n'
  out+="|---------|------|--------|"$'\n'

  while IFS= read -r line; do
    local modes keys desc
    desc=$(echo "$line" | grep -oP 'desc = "\K[^"]+' 2>/dev/null || true)
    [[ -z "$desc" ]] && continue

    # Single mode: map("n", "<key>", ...)
    if [[ "$line" =~ map\(\"([a-z]+)\",[[:space:]]*\"([^\"]+)\" ]]; then
      modes="${BASH_REMATCH[1]}"
      keys="${BASH_REMATCH[2]}"
    # Multi mode: map({ "n", "v" }, "<key>", ...)
    elif [[ "$line" =~ map\(\{[[:space:]]*\"([^\"]+)\"[[:space:]]*,[[:space:]]*\"([^\"]+)\"[[:space:]]*\},[[:space:]]*\"([^\"]+)\" ]]; then
      modes="${BASH_REMATCH[1]},${BASH_REMATCH[2]}"
      keys="${BASH_REMATCH[3]}"
    else
      continue
    fi

    if [[ -n "$keys" && -n "$desc" ]]; then
      out+="| \`$keys\` | $modes | $desc |"$'\n'
    fi
  done < "$nvim_keys"

  out+=$'\n'"## Tmux (Prefix = \`\` \` \`\`)"$'\n\n'
  out+="| Binding | Action |"$'\n'
  out+="|---------|--------|"$'\n'

  while IFS= read -r line; do
    if [[ "$line" =~ bind[[:space:]] ]]; then
      local key desc
      key=$(echo "$line" | sed -E 's/.*bind\s+(-[a-zA-Z]+\s+)?//' | awk '{print $1}' || true)
      desc=$(echo "$line" | grep -oP 'display-message "\K[^"]+' 2>/dev/null || true)
      if [[ -z "$desc" ]]; then
        desc=$(echo "$line" | sed -E 's/.*bind\s+(-[a-zA-Z]+\s+)?\S+\s+//' | head -c 60 || true)
      fi
      if [[ -n "$key" && -n "$desc" ]]; then
        out+="| \`$key\` | $desc |"$'\n'
      fi
    fi
  done < "$tmux_file"

  write_if_changed "$WIKI_DIR/Keybindings.md" "$out"
}

# =============================================================================
# 5. Shell Environment (Fish abbreviations)
# =============================================================================
generate_shell() {
  local shared_file="$REPO_ROOT/modules/home/shell/shared.nix"
  local fish_file="$REPO_ROOT/modules/home/shell/fish.nix"

  local out
  out="# Shell Environment

> **Auto-generated** from \`modules/home/shell/shared.nix\` and \`fish.nix\` by \`scripts/generate-wiki.sh\`.
> Edit the generator, not this page.

## Fish Abbreviations

| Abbreviation | Expands To |
|-------------|------------|
"

  local in_aliases=0
  while IFS= read -r line; do
    if [[ "$line" == *"sharedAliases"* ]]; then
      in_aliases=1; continue
    fi
    if [[ $in_aliases -eq 1 ]]; then
      if [[ "$line" =~ ^[[:space:]]+\}\; ]]; then break; fi
      local abbr expansion
      # Match: key = "value"; or "key" = "value";
      if [[ "$line" =~ ^[[:space:]]+\"([^\"]+)\"[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        abbr="${BASH_REMATCH[1]}"
        expansion="${BASH_REMATCH[2]}"
      elif [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        abbr="${BASH_REMATCH[1]}"
        expansion="${BASH_REMATCH[2]}"
      fi
      if [[ -n "$abbr" && -n "$expansion" ]]; then
        out+="| \`$abbr\` | \`$expansion\` |"$'\n'
      fi
    fi
  done < "$shared_file"

  out+=$'\n'"## Fish Plugins"$'\n\n'

  while IFS= read -r line; do
    local plugin
    plugin=$(echo "$line" | grep -oP 'name = "\K[^"]+' 2>/dev/null || true)
    if [[ -n "$plugin" ]]; then
      out+="- **$plugin**"$'\n'
    fi
  done < "$fish_file"

  out+="
## Tmux

- **Prefix:** Backtick (\`\` \` \`\`)
- **Vi mode** for copy mode
- **Smart pane navigation:** Ctrl+HJKL passes through to Neovim when at a split edge
- **Plugins:** sensible, resurrect, continuum, yank, prefix-highlight, vim-tmux-navigator
- **Status bar:** Top position, Stylix-colored

## Zellij

Alternative multiplexer with tmux-compatible keybinds:
- **Prefix:** Backtick (Tmux mode)
- Same pane splitting/resizing/navigation as tmux
- Session serialization enabled
- Stylix theme via RGB values

## Terminal: Foot

- **Font:** JetBrains Mono Nerd Font, 12pt
- **Padding:** 20x20
- **Shell:** Fish
- **Colors:** Full 16-color palette from Stylix
"

  write_if_changed "$WIKI_DIR/Shell-Environment.md" "$out"
}

# =============================================================================
# 6. Custom Scripts
# =============================================================================
generate_scripts() {
  local scripts_file="$REPO_ROOT/modules/home/scripts.nix"

  local out
  out="# Custom Scripts

> **Auto-generated** from \`modules/home/scripts.nix\` by \`scripts/generate-wiki.sh\`.
> Edit the generator, not this page.

All scripts are placed on \`\$PATH\` via \`writeShellScriptBin\`.

| Script | Description |
|--------|-------------|
"

  local current_desc=""
  while IFS= read -r line; do
    # Match comment: "── Name ──"
    if [[ "$line" =~ ──[[:space:]]+(.+)[[:space:]]+── ]]; then
      current_desc="${BASH_REMATCH[1]}"
    fi
    # Match writeShellScriptBin "name"
    if [[ "$line" =~ writeShellScriptBin[[:space:]]+\"([^\"]+)\" ]]; then
      local sname="${BASH_REMATCH[1]}"
      out+="| \`$sname\` | ${current_desc:-_See scripts.nix_} |"$'\n'
      current_desc=""
    fi
  done < "$scripts_file"

  write_if_changed "$WIKI_DIR/Custom-Scripts.md" "$out"
}

# =============================================================================
# Run all generators
# =============================================================================
generate_flake_inputs
generate_stylix_themes
generate_neovim
generate_keybindings
generate_shell
generate_scripts

echo
echo "Done! Review changes in $WIKI_DIR and commit when ready."
