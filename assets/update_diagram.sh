#!/usr/bin/env bash
# Update the generated README blocks.
# The Mermaid diagram is built from modules/, and the repository tree is built
# from the filesystem. Both live between HTML comment markers.
#
# Usage:
#   ./assets/update_diagram.sh [--check]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$REPO_ROOT/README.md"
CHECK_ONLY=false

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

# Print an indented tree. Hidden entries and build outputs are skipped.
tree_listing() {
  local base="$1" prefix="$2" depth="$3"
  ((depth > 0)) || return 0

  local entries=() entry
  while IFS= read -r entry; do
    entries+=("$entry")
  done < <(
    find "$base" -mindepth 1 -maxdepth 1 \
      -not -name '.*' -not -name 'result' -not -name 'nohup.out' \
      -printf '%f\n' | LC_ALL=C sort
  )

  local i=0 total=${#entries[@]} connector child_prefix
  for entry in "${entries[@]}"; do
    i=$((i + 1))
    connector="├── "
    if ((i == total)); then connector="└── "; fi

    if [[ -d "$base/$entry" ]]; then
      printf '%s%s%s/\n' "$prefix" "$connector" "$entry"
      if ((i == total)); then
        child_prefix="$prefix    "
      else
        child_prefix="$prefix│   "
      fi
      tree_listing "$base/$entry" "$child_prefix" $((depth - 1))
    else
      printf '%s%s%s\n' "$prefix" "$connector" "$entry"
    fi
  done
}

TREE_BODY=$(tree_listing "$REPO_ROOT" "" 4)
export TREE_CONTENT=$(cat <<EOF
<!-- TREE:START -->
\`\`\`
$TREE_BODY
\`\`\`
<!-- TREE:END -->
EOF
)

# Detect features
FEATURES=()
for f in "$REPO_ROOT/modules/features"/*/; do
  [[ -d "$f" ]] || continue
  FEATURES+=("$(basename "$f")")
done

# Detect packages
PACKAGES=()
for p in "$REPO_ROOT/modules/packages"/*/; do
  [[ -d "$p" ]] || continue
  PACKAGES+=("$(basename "$p")")
done

FEATURES_STR=$(printf "%s, " "${FEATURES[@]}" | sed 's/, $//')
PACKAGES_STR=$(printf "%s, " "${PACKAGES[@]}" | sed 's/, $//')

# Detect hosts
HOSTS=()
for h in "$REPO_ROOT/modules/hosts"/*/; do
  [[ -d "$h" ]] || continue
  HOSTS+=("$(basename "$h")")
done

HOST_NODES=""
HOST_EDGES=""
HOST_CLICKS=""
i=0
for h in "${HOSTS[@]}"; do
  HOST_NODES+="        Host$i[\"nixosConfigurations.$h<br/>modules/hosts/$h/\"]"$'\n'
  HOST_EDGES+="    Shared --> Host$i"$'\n'
  HOST_CLICKS+="    click Host$i href \"modules/hosts/$h\" \"Open the $h host configuration\""$'\n'
  i=$((i + 1))
done

# Build new Mermaid diagram
export DIAGRAM_CONTENT=$(cat <<EOF
<!-- DIAGRAM:START -->
\`\`\`mermaid
flowchart TD
    subgraph Flake["flake.nix (Flake-Parts Entry Point)"]
        Inputs["Inputs: nixpkgs (unstable default), stable, flake-parts, import-tree, hjem, nix-flatpak, nvf, mangowc, pi-agent..."]
    end

    Tree["inputs.import-tree ./modules<br/>(Filesystem Auto-Discovery)"]
    Flake --> Tree

    subgraph Modules["Dendritic Modules Structure"]
        Core["modules/core/<br/>helpers, live-links, options, parts, devshell, templates"]
        Features["modules/features/<br/>${FEATURES_STR}"]
        Packages["modules/packages/<br/>${PACKAGES_STR}"]
    end

    Tree --> Core
    Tree --> Features
    Tree --> Packages

    subgraph Composition["Deferred Module Group"]
        Shared["nixos.modules.shared<br/>(Base OS, Shell, Audio, Networking, Desktop Apps)"]
    end

    Core --> Composition
    Features --> Composition
    Packages --> Composition

    subgraph Hosts["Target Machine Configurations"]
${HOST_NODES}    end

${HOST_EDGES}
    click Core href "modules/core" "Open core modules"
    click Features href "modules/features" "Open features modules"
    click Packages href "modules/packages" "Open custom packages"
${HOST_CLICKS}\`\`\`
<!-- DIAGRAM:END -->
EOF
)

if [[ "$CHECK_ONLY" == true ]]; then
  perl -0777 -e '
    my $readme = do { local $/; <> };
    my $diag = $ENV{"DIAGRAM_CONTENT"};
    my $tree = $ENV{"TREE_CONTENT"};
    my $copy = $readme;
    $copy =~ s/<!-- DIAGRAM:START -->.*?<!-- DIAGRAM:END -->/$diag/s;
    $copy =~ s/<!-- TREE:START -->.*?<!-- TREE:END -->/$tree/s;
    if ($readme eq $copy) {
      print "README generated blocks are up to date.\n";
      exit 0;
    } else {
      print "README generated blocks are out of date. Run ./assets/update_diagram.sh to update.\n";
      exit 1;
    }
  ' "$README"
  exit $?
fi

perl -0777 -i -e '
  my $readme = do { local $/; <> };
  my $diag = $ENV{"DIAGRAM_CONTENT"};
  my $tree = $ENV{"TREE_CONTENT"};
  $readme =~ s/<!-- DIAGRAM:START -->.*?<!-- DIAGRAM:END -->/$diag/s;
  $readme =~ s/<!-- TREE:START -->.*?<!-- TREE:END -->/$tree/s;
  print $readme;
' "$README"

echo "Updated the architecture diagram and repository tree in README.md"
