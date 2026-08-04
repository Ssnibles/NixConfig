#!/usr/bin/env bash
# =============================================================================
# NixOS Rebuild + Commit
# =============================================================================
# Rebuild a NixOS host, then commit the configuration changes with a message
# that includes the new generation number. The commit body is auto-filled with
# build details.
#
# Usage:
#   ./build.sh <host> [switch|boot|test|build] [options]
#   ./build.sh desktop
#   ./build.sh laptop switch
#   ./build.sh desktop switch -m "add steam and gamescope"
#   ./build.sh desktop switch --no-commit
# =============================================================================
set -euo pipefail

# ── Configuration ───────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_COMMAND="switch"

# Auto-detect hosts from modules/hosts/*/ if the directory exists.
HOSTS=()
if [[ -d "$REPO_ROOT/modules/hosts" ]]; then
  for host_dir in "$REPO_ROOT/modules/hosts"/*/; do
    [[ -d "$host_dir" ]] || continue
    HOSTS+=("$(basename "$host_dir")")
  done
fi
[[ ${#HOSTS[@]} -eq 0 ]] && HOSTS=(desktop laptop)

# Conventional commit types. Includes the spec-standard ones plus a few
# commonly used extensions.
CONVENTIONAL_TYPES=(
  feat
  fix
  docs
  style
  refactor
  perf
  test
  build
  ci
  chore
  revert
  security
  deps
  init
  wip
)

# ── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}  ->${NC} $*"; }
success() { echo -e "${GREEN}  OK${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}  ERROR:${NC} $*" >&2; exit 1; }
heading() { echo -e "\n${BOLD}---  $*  ---${NC}"; }

# ── Usage ───────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: ${BASH_SOURCE[0]##*/} <host> [command] [options]

  host        NixOS host to build (${HOSTS[*]})
  command     nixos-rebuild action: switch | boot | test | build
              (default: ${DEFAULT_COMMAND})

Options:
  -m, --message <text>   Description of the change. If omitted, you will be
                         prompted. Combine with -t/-s to build a full
                         conventional commit subject.
  -t, --type <type>      Conventional commit type (e.g. feat, fix, chore).
  -s, --scope <scope>    Conventional commit scope (e.g. niri, desktop).
  -c, --command <cmd>    nixos-rebuild action (same as the positional command).
  -b, --no-build         Skip the nixos-rebuild step and only commit the
                         current changes (uses the current generation).
  -n, --no-commit        Build but do not create a git commit.
  -h, --help             Show this help text.

Examples:
  ${BASH_SOURCE[0]##*/} desktop
  ${BASH_SOURCE[0]##*/} laptop switch
  ${BASH_SOURCE[0]##*/} desktop boot -m "pin kernel for nvidia"
  ${BASH_SOURCE[0]##*/} desktop test
  ${BASH_SOURCE[0]##*/} laptop switch -t feat -s niri -m "add sticky rules"
  ${BASH_SOURCE[0]##*/} desktop --no-build
  ${BASH_SOURCE[0]##*/} desktop --no-build -m "document new host"
EOF
}

# ── Helpers ─────────────────────────────────────────────────────────────────

# Ask for input from the controlling terminal so the script can be piped.
ask() {
  local var="$1"
  local prompt="$2"
  local default="${3:-}"
  local input
  if [[ -n "$default" ]]; then
    read -rp "$prompt [$default]: " input < /dev/tty
    printf -v "$var" '%s' "${input:-$default}"
  else
    read -rp "$prompt: " input < /dev/tty
    printf -v "$var" '%s' "$input"
  fi
}

# Return the current (latest) NixOS generation number.
get_current_generation() {
  nixos-rebuild list-generations 2>/dev/null | awk 'NR==2 {print $1}'
}

# Return the NixOS version string.
get_nixos_version() {
  nixos-version 2>/dev/null || echo "unknown"
}

# Return the running kernel version.
get_kernel() {
  uname -r
}

# Return a UTC timestamp.
get_build_timestamp() {
  date -u +"%Y-%m-%d %H:%M:%S UTC"
}

# Show a compact summary of changed inputs in flake.lock. Prefers the staged
# diff when the user has manually staged changes, otherwise falls back to the
# unstaged diff.
get_flake_lock_summary() {
  local diff_cmd=""
  if ! git diff --cached --quiet -- flake.lock 2>/dev/null; then
    diff_cmd="git diff --cached"
  elif ! git diff --quiet -- flake.lock 2>/dev/null; then
    diff_cmd="git diff"
  else
    echo "none"
    return
  fi
  $diff_cmd -- flake.lock 2>/dev/null | awk '
    /^--- a\/flake.lock/ { next }
    /^+++ b\/flake.lock/ { next }
    /^@@/ { next }
    /^[-+].*"lastModified"/ {
      gsub(/^[-+]  /, "")
      print
    }
  ' | head -n 40 || echo "(diff too large)"
}

# Build a list of conventional commit scopes from the repository structure.
# Hosts, feature modules, and layer modules are included as suggestions.
derive_scopes() {
  local scopes=()
  # hosts
  if [[ -d "$REPO_ROOT/modules/hosts" ]]; then
    for host_dir in "$REPO_ROOT/modules/hosts"/*/; do
      [[ -d "$host_dir" ]] || continue
      scopes+=("$(basename "$host_dir")")
    done
  fi
  # feature modules and layers
  if [[ -d "$REPO_ROOT/modules/features" ]]; then
    for feature_dir in "$REPO_ROOT/modules/features"/*/; do
      [[ -d "$feature_dir" ]] || continue
      local name
      name="$(basename "$feature_dir")"
      # skip nested layers parent, we collect those separately
      [[ "$name" == "layers" ]] && continue
      scopes+=("$name")
    done
  fi
  if [[ -d "$REPO_ROOT/modules/features/layers" ]]; then
    for layer_file in "$REPO_ROOT/modules/features/layers"/*.nix; do
      [[ -f "$layer_file" ]] || continue
      local name
      name="$(basename "$layer_file" .nix)"
      scopes+=("$name")
    done
  fi
  # core / repo-level scopes
  scopes+=(flake root)
  # sort and dedupe
  printf '%s\n' "${scopes[@]}" | sort -u
}

# Present a list of items and return the selected item.
# If fzf is available, use it; otherwise use a simple numbered menu.
pick_item() {
  local prompt="$1"
  local allow_custom="${2:-false}"
  shift 2
  local items=("$@")

  if command -v fzf >/dev/null 2>&1; then
    # Unset FZF_DEFAULT_COMMAND so fzf uses the piped items instead of falling
    # back to a command that lists files (e.g. the default file picker).
    if [[ "$allow_custom" == true ]]; then
      # --print-query lets the user type a custom item not in the list.
      printf '%s\n' "${items[@]}" | FZF_DEFAULT_COMMAND= fzf \
        --prompt="$prompt" \
        --print-query \
        --height="~40%" \
        --border | tail -n 1 || true
    else
      printf '%s\n' "${items[@]}" | FZF_DEFAULT_COMMAND= fzf \
        --prompt="$prompt" \
        --height="~40%" \
        --border || true
    fi
    return 0
  fi

  # Fallback: simple numbered menu.
  echo "$prompt" >&2
  local i
  for i in "${!items[@]}"; do
    echo "  $((i+1)). ${items[$i]}" >&2
  done
  if [[ "$allow_custom" == true ]]; then
    echo "  (type a custom name and press Enter)" >&2
  fi
  local choice_prompt="  Select number"
  [[ "$allow_custom" == true ]] && choice_prompt="  Select number or type a custom name"
  local choice
  read -rp "$choice_prompt: " choice </dev/tty
  if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#items[@]} ]]; then
    echo "${items[$((choice-1))]}"
  elif [[ "$allow_custom" == true && -n "$choice" ]]; then
    echo "$choice"
  else
    echo ""
  fi
}

# Ask the user for a one-line description of the change.
ask_description() {
  local description
  ask description "  Enter a short description of the changes" ""
  printf '%s' "$description"
}

# Assemble a conventional commit subject with the generation at the end.
# Examples:
#   feat(niri): make some change (gen 168)
#   fix: patch something (gen 168)
assemble_subject() {
  local type="$1"
  local scope="$2"
  local description="$3"
  local gen="$4"

  local prefix
  if [[ -n "$scope" && "$scope" != "<none>" ]]; then
    prefix="${type}(${scope}):"
  else
    prefix="${type}:"
  fi

  echo "${prefix} ${description} (gen ${gen})"
}

# Validate the requested host against available hosts.
validate_host() {
  local host="$1"
  for h in "${HOSTS[@]}"; do
    [[ "$h" == "$host" ]] && return 0
  done
  die "Unknown host '$host'. Available hosts: ${HOSTS[*]}"
}

# Validate the nixos-rebuild command.
validate_command() {
  local cmd="$1"
  case "$cmd" in
    switch|boot|test|build) return 0 ;;
    *) die "Unknown command '$cmd'. Available: switch, boot, test, build" ;;
  esac
}

# Validate a conventional commit type.
validate_type() {
  local type="$1"
  for t in "${CONVENTIONAL_TYPES[@]}"; do
    [[ "$t" == "$type" ]] && return 0
  done
  die "Unknown commit type '$type'. Available: ${CONVENTIONAL_TYPES[*]}"
}

# Build the requested host. Uses sudo.
run_build() {
  local host="$1"
  local cmd="$2"
  heading "Building NixOS configuration"
  info "Host:    $host"
  info "Command: nixos-rebuild $cmd"
  info "Flake:   $REPO_ROOT"
  sudo nixos-rebuild "$cmd" --flake "$REPO_ROOT#$host"
  success "Build completed"
}

# Build a commit subject using a conventional commit picker.
# If the user passed a full conventional commit subject via -m (e.g.
# "feat(niri): make some change"), it is reused and (gen N) is appended.
# If the user passed a plain description via -m, it is combined with any
# passed type (-t) and scope (-s); missing parts are picked interactively.
build_commit_subject() {
  local host="$1"
  local cmd="$2"
  local gen="$3"
  local type="$4"
  local scope="$5"
  local description="$6"

  # If a full conventional commit subject was passed, append the generation
  # and skip the picker.
  local subject_re='^([a-z]+)(\([^)]*\))?:[[:space:]]+(.+)$'
  local gen_re='\(gen[[:space:]]+[0-9]+\)$'
  if [[ -n "$description" && "$description" =~ $subject_re ]]; then
    local prefix_type="${BASH_REMATCH[1]}"
    local valid=false
    for t in "${CONVENTIONAL_TYPES[@]}"; do
      if [[ "$t" == "$prefix_type" ]]; then
        valid=true
        break
      fi
    done
    if [[ "$valid" == true ]]; then
      if [[ "$description" =~ $gen_re ]]; then
        echo "$description"
      else
        echo "${description} (gen ${gen})"
      fi
      return 0
    fi
  fi

  local picked_type="$type"
  local picked_scope="$scope"
  local picked_description="$description"

  if [[ -z "$picked_type" ]]; then
    heading "Select conventional commit type"
    picked_type="$(pick_item "type: " false "${CONVENTIONAL_TYPES[@]}")"
    [[ -z "$picked_type" ]] && die "No commit type selected"
  fi

  if [[ -z "$picked_scope" ]]; then
    heading "Select scope (optional)"
    local scopes
    scopes=("<none>" $(derive_scopes))
    picked_scope="$(pick_item "scope: " true "${scopes[@]}")"
    [[ -z "$picked_scope" ]] && picked_scope="<none>"
  fi

  if [[ -z "$picked_description" ]]; then
    heading "Describe the change"
    picked_description="$(ask_description)"
    if [[ -z "$picked_description" ]]; then
      warn "No description provided; using default"
      picked_description="${host} ${cmd}"
    fi
  fi

  assemble_subject "$picked_type" "$picked_scope" "$picked_description" "$gen"
}

# Create a git commit with the given subject and an auto-generated body.
# If $staged_only is true, the commit is created from the user's manually
# staged changes; otherwise it is assumed all changes are already staged.
commit_changes() {
  local host="$1"
  local cmd="$2"
  local gen="$3"
  local subject="$4"
  local staged_only="$5"
  local previous_revision
  previous_revision="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"

  heading "Creating commit"
  info "Subject: ${subject}"

  local commit_source
  if [[ "$staged_only" == true ]]; then
    commit_source="manually staged files"
  else
    commit_source="all changes (auto-staged)"
  fi

  local changed_files
  changed_files="$(git -C "$REPO_ROOT" diff --cached --stat)"

  local body
  body="NixOS configuration rebuild for host ${host}.

Host:            ${host}
Command:         nixos-rebuild ${cmd}
Generation:      ${gen}
Previous HEAD:   ${previous_revision}
NixOS version:   $(get_nixos_version)
Kernel:          $(get_kernel)
Build timestamp: $(get_build_timestamp)
Commit source:   ${commit_source}

Flake lock changes:
$(get_flake_lock_summary)

Changed files:
${changed_files}"

  git -C "$REPO_ROOT" commit -m "$subject" -m "$body"
  success "Committed changes"
}

main() {
  # ── Argument parsing ────────────────────────────────────────────────────────
  local HOST=""
  local COMMAND=""
  local MESSAGE=""
  local TYPE=""
  local SCOPE=""
  local NO_BUILD=false
  local NO_COMMIT=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--message)
        [[ $# -lt 2 ]] && die "Option $1 requires a value"
        MESSAGE="$2"; shift 2 ;;
      -t|--type)
        [[ $# -lt 2 ]] && die "Option $1 requires a value"
        TYPE="$2"; shift 2 ;;
      -s|--scope)
        [[ $# -lt 2 ]] && die "Option $1 requires a value"
        SCOPE="$2"; shift 2 ;;
      -c|--command)
        [[ $# -lt 2 ]] && die "Option $1 requires a value"
        COMMAND="$2"; shift 2 ;;
      -b|--no-build)
        NO_BUILD=true; shift ;;
      -n|--no-commit)
        NO_COMMIT=true; shift ;;
      -h|--help)
        usage; exit 0 ;;
      -*)
        die "Unknown option: $1" ;;
      *)
        if [[ -z "$HOST" ]]; then
          HOST="$1"
        elif [[ -z "$COMMAND" ]]; then
          COMMAND="$1"
        else
          die "Unexpected argument: $1"
        fi
        shift ;;
    esac
  done

  [[ -z "$HOST" ]] && { usage; exit 1; }
  [[ -z "$COMMAND" ]] && COMMAND="$DEFAULT_COMMAND"

  validate_host "$HOST"
  validate_command "$COMMAND"
  if [[ -n "$TYPE" ]]; then
    validate_type "$TYPE"
  fi

  # ── Preflight ───────────────────────────────────────────────────────────────
  heading "NixOS rebuild + commit"
  if [[ ! -d "$REPO_ROOT/.git" ]]; then
    die "This does not look like a git repository: $REPO_ROOT"
  fi
  if ! command -v nixos-rebuild >/dev/null 2>&1; then
    die "Command 'nixos-rebuild' not found. Are you on NixOS?"
  fi
  if [[ "$NO_BUILD" == true && "$NO_COMMIT" == true ]]; then
    warn "Both --no-build and --no-commit are set; nothing to do"
    exit 0
  fi

  if [[ "$NO_BUILD" != true && $EUID -ne 0 && "$COMMAND" != "build" ]]; then
    # switch/boot/test need root; build can sometimes run without, but we still
    # use sudo for consistency.
    info "Rebuild requires root privileges; sudo will be used."
  fi

  local GENERATION=""

  # ── Build ───────────────────────────────────────────────────────────────────
  if [[ "$NO_BUILD" == true ]]; then
    heading "Skipping build (--no-build)"
    GENERATION="$(get_current_generation)"
    if [[ -z "$GENERATION" ]]; then
      warn "Could not determine generation number from nixos-rebuild"
      GENERATION="unknown"
    fi
    info "Current generation: $GENERATION"
  else
    run_build "$HOST" "$COMMAND"

    # ── Get generation ──────────────────────────────────────────────────────────
    GENERATION="$(get_current_generation)"
    if [[ -z "$GENERATION" ]]; then
      warn "Could not determine generation number from nixos-rebuild"
      GENERATION="unknown"
    fi
    info "Current generation: $GENERATION"

    # ── Commit ────────────────────────────────────────────────────────────────────
    if [[ "$NO_COMMIT" == true ]]; then
      heading "Done"
      success "Built $HOST with nixos-rebuild $COMMAND (generation $GENERATION)"
      info "--no-commit was set; no git commit created."
      exit 0
    fi
  fi

  # Detect manually staged changes. If the user has staged files, commit only
  # those. Otherwise stage all current changes and commit them.
  local STAGED_ONLY=false
  if ! git -C "$REPO_ROOT" diff --cached --quiet; then
    STAGED_ONLY=true
    info "Manually staged changes detected; will commit only those"
  elif git -C "$REPO_ROOT" status --short | grep -q .; then
    info "No staged changes found; staging all changes"
    git -C "$REPO_ROOT" add -A
  else
    warn "No changes to commit"
    heading "Done"
    if [[ "$NO_BUILD" == true ]]; then
      success "No build and no commit performed"
    else
      success "Built $HOST with nixos-rebuild $COMMAND (generation $GENERATION)"
    fi
    exit 0
  fi

  local SUBJECT
  SUBJECT="$(build_commit_subject "$HOST" "$COMMAND" "$GENERATION" "$TYPE" "$SCOPE" "$MESSAGE")"
  commit_changes "$HOST" "$COMMAND" "$GENERATION" "$SUBJECT" "$STAGED_ONLY"

  heading "Done"
  if [[ "$NO_BUILD" == true ]]; then
    success "Committed changes as generation $GENERATION"
  else
    success "Built $HOST with nixos-rebuild $COMMAND and committed as generation $GENERATION"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
