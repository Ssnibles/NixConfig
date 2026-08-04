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
  -m, --message <text>   Use this text as the human-readable part of the
                         commit subject. If omitted, you will be prompted.
  -c, --command <cmd>    nixos-rebuild action (same as the positional command).
  -n, --no-commit        Build but do not create a git commit.
  -h, --help             Show this help text.

Examples:
  ${BASH_SOURCE[0]##*/} desktop
  ${BASH_SOURCE[0]##*/} laptop switch
  ${BASH_SOURCE[0]##*/} desktop boot -m "pin kernel for nvidia"
  ${BASH_SOURCE[0]##*/} desktop test
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

# Show a compact summary of changed inputs in flake.lock.
get_flake_lock_summary() {
  if git diff --quiet -- flake.lock 2>/dev/null; then
    echo "none"
    return
  fi
  git diff -- flake.lock 2>/dev/null | awk '
    /^--- a\/flake.lock/ { next }
    /^+++ b\/flake.lock/ { next }
    /^@@/ { next }
    /^[-+].*"lastModified"/ {
      gsub(/^[-+]  /, "")
      print
    }
  ' | head -n 40 || echo "(diff too large)"
}

# Return a short summary of changed files.
get_changed_files_summary() {
  local summary
  summary="$(git status --short)"
  if [[ -z "$summary" ]]; then
    echo "none"
  else
    echo "$summary"
  fi
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

# Prompt the user for the human-readable part of the commit subject.
ask_commit_message() {
  local host="$1"
  local cmd="$2"
  local gen="$3"
  local message
  ask message "  Enter a short description of the changes" ""
  if [[ -z "$message" ]]; then
    warn "No message provided; using default."
    message="${host} ${cmd}"
  fi
  printf '%s' "$message"
}

# Create a git commit with the given generation and message.
commit_changes() {
  local host="$1"
  local cmd="$2"
  local gen="$3"
  local message="$4"
  local previous_revision
  previous_revision="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"

  heading "Creating commit"
  info "Subject: gen ${gen}: ${message}"

  local body
  body="NixOS configuration rebuild for host ${host}.

Host:            ${host}
Command:         nixos-rebuild ${cmd}
Generation:      ${gen}
Previous HEAD:   ${previous_revision}
NixOS version:   $(get_nixos_version)
Kernel:          $(get_kernel)
Build timestamp: $(get_build_timestamp)

Flake lock changes:
$(get_flake_lock_summary)

Changed files:
$(get_changed_files_summary)"

  git -C "$REPO_ROOT" add -A
  git -C "$REPO_ROOT" commit -m "gen ${gen}: ${message}" -m "$body"
  success "Committed changes"
}

# ── Argument parsing ────────────────────────────────────────────────────────
HOST=""
COMMAND=""
MESSAGE=""
NO_COMMIT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      [[ $# -lt 2 ]] && die "Option $1 requires a value"
      MESSAGE="$2"; shift 2 ;;
    -c|--command)
      [[ $# -lt 2 ]] && die "Option $1 requires a value"
      COMMAND="$2"; shift 2 ;;
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

# ── Preflight ───────────────────────────────────────────────────────────────
heading "NixOS rebuild + commit"
if [[ ! -d "$REPO_ROOT/.git" ]]; then
  die "This does not look like a git repository: $REPO_ROOT"
fi
if ! command -v nixos-rebuild >/dev/null 2>&1; then
  die "Command 'nixos-rebuild' not found. Are you on NixOS?"
fi
if [[ $EUID -ne 0 && "$COMMAND" != "build" ]]; then
  # switch/boot/test need root; build can sometimes run without, but we still
  # use sudo for consistency.
  info "Rebuild requires root privileges; sudo will be used."
fi

# ── Build ───────────────────────────────────────────────────────────────────
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

# If there is nothing to commit after the build, skip the commit.
if ! git -C "$REPO_ROOT" status --short | grep -q .; then
  warn "No changes to commit after build"
  heading "Done"
  success "Built $HOST with nixos-rebuild $COMMAND (generation $GENERATION)"
  exit 0
fi

if [[ -z "$MESSAGE" ]]; then
  MESSAGE="$(ask_commit_message "$HOST" "$COMMAND" "$GENERATION")"
fi

commit_changes "$HOST" "$COMMAND" "$GENERATION" "$MESSAGE"

heading "Done"
success "Built $HOST with nixos-rebuild $COMMAND and committed as generation $GENERATION"
