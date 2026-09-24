#!/usr/bin/env bash
# =============================================================================
# Update Interactive Architecture Diagram in README.md
# =============================================================================
# Scans modules/ and updates the Mermaid diagram between:
#   <!-- DIAGRAM:START --> and <!-- DIAGRAM:END -->
#
# Usage:
#   ./assets/update_diagram.sh [--check]
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$REPO_ROOT/README.md"
CHECK_ONLY=false

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

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

# Build new Mermaid diagram
export DIAGRAM_CONTENT=$(cat <<EOF
<!-- DIAGRAM:START -->
\`\`\`mermaid
flowchart TD
    subgraph Flake["flake.nix (Flake-Parts Entry Point)"]
        Inputs["Inputs: nixpkgs (26.05), unstable, flake-parts, import-tree, hjem, nvf, mangowc, pi-agent..."]
    end

    Tree["inputs.import-tree ./modules<br/>(Filesystem Auto-Discovery)"]
    Flake --> Tree

    subgraph Modules["Dendritic Modules Structure"]
        Core["modules/core/<br/>module-groups, options, parts, devshell, templates"]
        Features["modules/features/<br/>${FEATURES_STR}"]
        Packages["modules/packages/<br/>${PACKAGES_STR}"]
    end

    Tree --> Core
    Tree --> Features
    Tree --> Packages

    subgraph Composition["Deferred Module Groups"]
        Shared["nixos.modules.shared<br/>(Base OS, Shell, Audio, Networking, Maintenance)"]
        DesktopGroup["nixos.modules.desktop<br/>(NVIDIA, Workstation Daemons, Hyprland, MangoWC)"]
        LaptopGroup["nixos.modules.laptop<br/>(AMD Radeon, TLP Battery Profiles, MangoWC)"]
    end

    Core --> Composition
    Features --> Composition
    Packages --> Composition

    subgraph Hosts["Target Machine Configurations"]
        DesktopHost["nixosConfigurations.desktop<br/>Workstation & Gaming Host"]
        LaptopHost["nixosConfigurations.laptop<br/>Ultraportable Productivity Host"]
    end

    Shared --> DesktopHost
    DesktopGroup --> DesktopHost
    Shared --> LaptopHost
    LaptopGroup --> LaptopHost

    click Core href "modules/core" "Open core modules"
    click Features href "modules/features" "Open features modules"
    click Packages href "modules/packages" "Open custom packages"
    click DesktopHost href "modules/hosts/desktop" "Open desktop host configuration"
    click LaptopHost href "modules/hosts/laptop" "Open laptop host configuration"
\`\`\`
<!-- DIAGRAM:END -->
EOF
)

if [[ "$CHECK_ONLY" == true ]]; then
  perl -0777 -e '
    my $readme = do { local $/; <> };
    my $diag = $ENV{"DIAGRAM_CONTENT"};
    my $copy = $readme;
    $copy =~ s/<!-- DIAGRAM:START -->.*?<!-- DIAGRAM:END -->/$diag/s;
    if ($readme eq $copy) {
      print "Architecture diagram is up to date.\n";
      exit 0;
    } else {
      print "Architecture diagram is out of date. Run ./assets/update_diagram.sh to update.\n";
      exit 1;
    }
  ' "$README"
  exit $?
fi

perl -0777 -i -e '
  my $readme = do { local $/; <> };
  my $diag = $ENV{"DIAGRAM_CONTENT"};
  $readme =~ s/<!-- DIAGRAM:START -->.*?<!-- DIAGRAM:END -->/$diag/s;
  print $readme;
' "$README"

echo "Successfully updated interactive architecture diagram in README.md"
