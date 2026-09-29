#!/usr/bin/env bash
# =============================================================================
# NixOS Rebuild + Commit
# =============================================================================
# Rebuild a NixOS host, then commit the config changes with a conventional
# commit message that records the generation (when knowable) and build details.
#
# Prefers jj + nh when available, falling back to git + nixos-rebuild.
#
# Usage:
#   ./build.sh [host] [switch|boot|test|build] [options]
#
#   ./build.sh                       rebuild + commit the current host
#   ./build.sh laptop                rebuild + commit another host
#   ./build.sh test                  test-build the current host
#   ./build.sh -n                    rebuild without committing
#   ./build.sh -m "fix: wifi drops"  rebuild + commit with a message
#   ./build.sh laptop boot -t feat -s niri -m "add sticky rules"
#   ./build.sh -b -m "docs: ..."     commit without rebuilding
#
# Host defaults to the current hostname and action to "switch". If -m is
# omitted on an interactive terminal, you're prompted for the commit message.
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Logging ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_BOLD=$'\e[1m'; C_RED=$'\e[31m'; C_GREEN=$'\e[32m'
  C_YELLOW=$'\e[33m'; C_BLUE=$'\e[34m'; C_OFF=$'\e[0m'
else
  C_BOLD="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_OFF=""
fi
info() { printf '%s  ->%s %s\n' "$C_BLUE" "$C_OFF" "$*" >&2; }
ok()   { printf '%s  ok%s %s\n' "$C_GREEN" "$C_OFF" "$*" >&2; }
warn() { printf '%s   !%s %s\n' "$C_YELLOW" "$C_OFF" "$*" >&2; }
die()  { printf '%s  err%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }
step() { printf '\n%s── %s ──%s\n' "$C_BOLD" "$*" "$C_OFF" >&2; }

usage() {
  cat <<'EOF'
Usage: build.sh [host] [switch|boot|test|build] [options]

  host     NixOS host to build (default: current hostname)
  action   nixos-rebuild action (default: switch)

Options:
  -m, --message <text>  Commit message / description
  -t, --type <type>     Conventional commit type (default: build)
  -s, --scope <scope>   Conventional commit scope
  -n, --no-commit       Rebuild but do not commit
  -b, --no-build        Commit without rebuilding
  -e, --edit            Edit the commit message in $EDITOR
  -y, --yes             Skip the proceed confirmation
  -h, --help            Show this help

Uses jj + nh when available, otherwise git + nixos-rebuild.
EOF
}

# ── Defaults & discovery ─────────────────────────────────────────────────────
HOST=""
ACTION="switch"
MESSAGE=""
TYPE="build"
SCOPE=""
DO_BUILD=true
DO_COMMIT=true
ASSUME_YES=false
EDIT_MESSAGE=false

HOSTS=()
for d in "$REPO_ROOT"/modules/hosts/*/; do
  [[ -d "$d" ]] && HOSTS+=("$(basename "$d")")
done
ACTIONS=(switch boot test build)

contains() { local n="$1"; shift; local i; for i in "$@"; do [[ "$i" == "$n" ]] && return 0; done; return 1; }

# ── Arguments ────────────────────────────────────────────────────────────────
positionals=()
while (($#)); do
  case "$1" in
    -m|--message)   [[ $# -ge 2 ]] || die "$1 needs a value"; MESSAGE="$2"; shift 2 ;;
    -t|--type)      [[ $# -ge 2 ]] || die "$1 needs a value"; TYPE="$2";    shift 2 ;;
    -s|--scope)     [[ $# -ge 2 ]] || die "$1 needs a value"; SCOPE="$2";   shift 2 ;;
    -n|--no-commit) DO_COMMIT=false;   shift ;;
    -b|--no-build)  DO_BUILD=false;    shift ;;
    -e|--edit)      EDIT_MESSAGE=true; shift ;;
    -y|--yes)       ASSUME_YES=true;   shift ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; positionals+=("$@"); break ;;
    -*)             die "unknown option '$1' (try --help)" ;;
    *)              positionals+=("$1"); shift ;;
  esac
done

# Host and action positionals may appear in any order.
for p in ${positionals[@]+"${positionals[@]}"}; do
  if [[ -z "$HOST" ]] && contains "$p" ${HOSTS[@]+"${HOSTS[@]}"}; then
    HOST="$p"
    contains "$p" "${ACTIONS[@]}" && warn "'$p' is both a host and an action; treating it as the host"
  elif contains "$p" "${ACTIONS[@]}"; then
    ACTION="$p"
  else
    die "unknown host or action '$p'"
  fi
done

LOCAL_HOST="$(hostname -s)"
[[ -n "$HOST" ]] || HOST="$LOCAL_HOST"
[[ "$TYPE" =~ ^[a-z]+$ ]] || die "invalid commit type '$TYPE'"

if [[ "$DO_BUILD" == true ]]; then
  contains "$HOST" ${HOSTS[@]+"${HOSTS[@]}"} || die "unknown host '$HOST' (available: ${HOSTS[*]:-none})"
  contains "$ACTION" "${ACTIONS[@]}" || die "unknown action '$ACTION'"
fi

# ── Tool detection ───────────────────────────────────────────────────────────
cd "$REPO_ROOT"

# Version control: prefer jj, otherwise require a git work tree.
USE_JJ=false
if command -v jj >/dev/null 2>&1 && jj -R "$REPO_ROOT" root >/dev/null 2>&1; then
  USE_JJ=true
elif ! command -v git >/dev/null 2>&1 \
  || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "neither jj nor a git work tree available in $REPO_ROOT"
fi

# Build tooling: prefer nh, otherwise require nixos-rebuild.
USE_NH=false
if [[ "$DO_BUILD" == true ]] && command -v nh >/dev/null 2>&1; then
  USE_NH=true
fi

# ── Preflight ────────────────────────────────────────────────────────────────
if [[ "$DO_BUILD" == true && "$USE_NH" == false ]] && ! command -v nixos-rebuild >/dev/null 2>&1; then
  die "neither nh nor nixos-rebuild available"
fi
if [[ "$DO_BUILD" == false && "$DO_COMMIT" == false ]]; then
  die "nothing to do (--no-build and --no-commit)"
fi
if [[ "$DO_BUILD" == true && "$HOST" != "$LOCAL_HOST" && "$ACTION" != build ]]; then
  die "'$ACTION' would activate $HOST's config on $LOCAL_HOST; use the 'build' action, or run this on $HOST"
fi
if [[ "$DO_COMMIT" == false ]] \
  && [[ "$TYPE" != build || -n "$SCOPE" || -n "$MESSAGE" || "$EDIT_MESSAGE" == true ]]; then
  warn "commit options (-t/-s/-m/-e) are ignored with --no-commit"
fi
if [[ "$EDIT_MESSAGE" == true && ! -t 0 ]]; then
  die "-e/--edit requires an interactive terminal"
fi

# ── Review ───────────────────────────────────────────────────────────────────
# A long rebuild followed by an auto-staged commit is easy to trigger by
# accident, so show what's about to happen first. Skipped for -y / non-TTY.
if [[ "$ASSUME_YES" != true && -t 0 ]]; then
  step "Review"
  info "host:   $HOST"
  info "action: $ACTION"
  if [[ "$DO_BUILD" == true ]]; then
    info "build:  $(if [[ "$USE_NH" == true ]]; then echo "nh os $ACTION"; else echo "nixos-rebuild $ACTION"; fi)"
  else
    info "build:  skipped (--no-build)"
  fi
  info "vcs:    $(if [[ "$USE_JJ" == true ]]; then echo jj; else echo git; fi)"
  if [[ "$DO_COMMIT" == true ]]; then
    if [[ "$USE_JJ" == true ]]; then
      info "will commit all changes:"
      changes="$(jj -R "$REPO_ROOT" status)"
    elif git diff --cached --quiet; then
      info "will commit all changes:"
      changes="$(git status --short)"
    else
      info "will commit staged changes only:"
      changes="$(git diff --cached --name-status)"
    fi
    if [[ -n "$changes" ]]; then
      printf '%s\n' "$changes" | sed 's/^/    /' >&2
    else
      warn "no changes to commit"
    fi
  else
    warn "commit disabled (--no-commit)"
  fi
  read -r -p "Proceed? [Y/n] " reply || true
  case "${reply:-y}" in
    [yY]|[yY][eE][sS]) ;;
    *) warn "aborted"; exit 1 ;;
  esac
fi

# ── Build ────────────────────────────────────────────────────────────────────
if [[ "$DO_BUILD" == true ]]; then
  step "Rebuilding $HOST"
  if [[ "$USE_NH" == true ]]; then
    info "nh os $ACTION $REPO_ROOT --hostname $HOST"
    nh os "$ACTION" "$REPO_ROOT" --hostname "$HOST"
  else
    info "sudo nixos-rebuild $ACTION --flake $REPO_ROOT#$HOST"
    sudo nixos-rebuild "$ACTION" --flake "$REPO_ROOT#$HOST"
  fi
  ok "build complete"
else
  warn "skipping build (--no-build)"
fi

if [[ "$DO_COMMIT" == false ]]; then
  ok "done (no commit requested)"
  exit 0
fi

# Only the local system profile is queryable; for other hosts (or `build`,
# which registers no generation) we can't know the resulting generation.
GEN="unknown"
if [[ "$HOST" == "$LOCAL_HOST" && "$ACTION" != build ]] \
  && command -v nixos-rebuild >/dev/null 2>&1; then
  newest_gen="$(nixos-rebuild list-generations 2>/dev/null \
    | awk 'NR > 1 && $1 ~ /^[0-9]+$/ { print $1 }' \
    | sort -n | tail -n 1)" || newest_gen=""
  [[ -n "$newest_gen" ]] && GEN="$newest_gen"
fi

# ── Stage ────────────────────────────────────────────────────────────────────
if [[ "$USE_JJ" == true ]]; then
  # jj has no staging area: `jj commit` takes the whole working copy.
  [[ -n "$(jj -R "$REPO_ROOT" diff --summary 2>/dev/null)" ]] || { warn "no changes to commit"; exit 0; }
  changed_stat="$(jj -R "$REPO_ROOT" diff --stat 2>/dev/null)"
else
  if git diff --cached --quiet; then
    [[ -n "$(git status --porcelain)" ]] || { warn "no changes to commit"; exit 0; }
    info "staging all changes"
    git add -A
  else
    info "committing staged changes only"
  fi
  changed_stat="$(git diff --cached --stat)"
fi

# ── Commit ───────────────────────────────────────────────────────────────────
if [[ -n "$SCOPE" ]]; then prefix="$TYPE($SCOPE):"; else prefix="$TYPE:"; fi

# A full conventional subject (e.g. "fix: thing") is used verbatim; anything
# else is treated as a description and prefixed with the type/scope. Either
# way the generation is appended once.
make_subject() {
  local gen="$1" msg="$2"
  local full_re='^[a-z]+(\([^)]*\))?:[[:space:]]+'
  local gen_re='\(gen[[:space:]]+[0-9]+\)$'
  local suffix=""
  [[ "$gen" =~ ^[0-9]+$ ]] && suffix=" (gen $gen)"
  if [[ "$msg" =~ $full_re ]]; then
    if [[ -z "$suffix" || "$msg" =~ $gen_re ]]; then
      printf '%s\n' "$msg"
    else
      printf '%s%s\n' "$msg" "$suffix"
    fi
  else
    printf '%s %s%s\n' "$prefix" "$msg" "$suffix"
  fi
}

# Prompt for the user's own subject; the generation is appended afterwards and
# the build details go in the body. Starts blank so the auto-generated fallback
# isn't mistaken for the intended message. Skipped with --edit, which opens the
# full message in $EDITOR instead.
if [[ -z "$MESSAGE" && "$EDIT_MESSAGE" != true && -t 0 ]]; then
  read -r -e -p 'Commit message: ' MESSAGE || true
fi
[[ -n "$MESSAGE" ]] || MESSAGE="$HOST $ACTION"

if [[ "$DO_BUILD" == true ]]; then
  body_head="NixOS configuration rebuild for $HOST."
  action_line="nixos-rebuild $ACTION"
  stamp_line="Built:      $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  gen_line="$GEN"
else
  body_head="NixOS configuration changes for $HOST (no rebuild)."
  action_line="none (--no-build)"
  stamp_line="Committed:  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  gen_line="$GEN"
  [[ "$GEN" != unknown ]] && gen_line="$GEN (current)"
fi

SUBJECT="$(make_subject "$GEN" "$MESSAGE")"
BODY="$(cat <<EOF
$body_head

Host:       $HOST
Action:     $action_line
Generation: $gen_line
NixOS:      $(nixos-version 2>/dev/null || echo unknown)
Kernel:     $(uname -r)
$stamp_line

Changed files:
$changed_stat
EOF
)"

step "Committing (gen $GEN)"
info "$SUBJECT"

if [[ "$USE_JJ" == true ]]; then
  if [[ "$EDIT_MESSAGE" == true ]]; then
    jj -R "$REPO_ROOT" commit -m "$SUBJECT

$BODY" --editor
  else
    jj -R "$REPO_ROOT" commit -m "$SUBJECT

$BODY"
  fi
else
  if [[ "$EDIT_MESSAGE" == true ]]; then
    git commit --edit -m "$SUBJECT" -m "$BODY"
  else
    git commit -m "$SUBJECT" -m "$BODY"
  fi
fi
ok "done"
