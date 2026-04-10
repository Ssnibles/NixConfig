#!/usr/bin/env bash
# =============================================================================
# NixOS Configuration Validation Script
# =============================================================================
# Performs pre-rebuild checks to catch common issues before building.
# Run before 'nixos-rebuild' or 'nh os switch' to validate changes.
#
# Critical checks (can fail script):
#   • Required command availability
#   • Repository structure sanity
#   • Merge conflict markers
#   • Nix + Bash syntax validation
#   • Host configuration integrity (dynamic host discovery)
#   • Flake output evaluation per host
#   • Flake checks + lock metadata validity
#
# Advisory checks (warnings only):
#   • Secret hygiene and placeholder keys
#   • Broken symlinks
#   • Dirty git working tree
#   • Flake lock age
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

readonly LOCK_AGE_DAYS=30
readonly SECRET_PATTERNS='(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{82}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|-----BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY-----)'

WARNING_COUNT=0

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Helper Functions ─────────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    ((WARNING_COUNT += 1))
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

strip_nix_noise() {
    sed \
        -e "/trusted-public-keys/d" \
        -e "/unknown flake output 'diskoConfigurations'/d"
}

discover_hosts() {
    local path host
    for path in hosts/*; do
        [[ -d "$path" ]] || continue
        host="${path#hosts/}"
        [[ -f "$path/default.nix" ]] || continue
        printf '%s\n' "$host"
    done | sort -u
}

# ── Validation Checks (Critical) ─────────────────────────────────────────────

check_required_commands() {
    log_info "Checking required commands..."
    local missing=0
    local cmd
    local -a required=(bash find git nix nix-instantiate)

    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Missing required command: $cmd"
            ((missing += 1))
        fi
    done

    if [[ $missing -eq 0 ]]; then
        log_success "All required commands are available"
        return 0
    fi

    log_error "Missing $missing required command(s)"
    return 1
}

check_repository_layout() {
    log_info "Checking repository layout..."
    local missing=0
    local path
    local -a required_files=(flake.nix check.sh lib/mkHost.nix)
    local -a required_dirs=(hosts modules users)

    for path in "${required_files[@]}"; do
        if [[ ! -f "$path" ]]; then
            log_error "Missing required file: $path"
            ((missing += 1))
        fi
    done

    for path in "${required_dirs[@]}"; do
        if [[ ! -d "$path" ]]; then
            log_error "Missing required directory: $path"
            ((missing += 1))
        fi
    done

    local -a hosts=()
    mapfile -t hosts < <(discover_hosts)
    if [[ ${#hosts[@]} -eq 0 ]]; then
        log_error "No host configurations found under hosts/*/default.nix"
        ((missing += 1))
    fi

    if [[ $missing -eq 0 ]]; then
        log_success "Repository layout looks good"
        return 0
    fi

    log_error "Repository layout check failed"
    return 1
}

check_merge_conflicts() {
    log_info "Checking for merge conflict markers..."
    local matches
    matches="$(
        git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- \
            '*.nix' '*.sh' '*.lua' '*.yaml' '*.yml' \
            2>/dev/null || true
    )"

    if [[ -n "$matches" ]]; then
        echo "$matches"
        log_error "Merge conflict markers found"
        return 1
    fi

    log_success "No merge conflict markers found"
    return 0
}

check_nix_syntax() {
    log_info "Checking Nix syntax..."
    local errors=0
    local file

    while IFS= read -r -d '' file; do
        if ! nix-instantiate --parse "$file" >/dev/null 2>&1; then
            log_error "Syntax error in: $file"
            ((errors += 1))
        fi
    done < <(find . -type f -name '*.nix' -not -path './.git/*' -print0)

    if [[ $errors -eq 0 ]]; then
        log_success "All Nix files have valid syntax"
        return 0
    fi

    log_error "Found $errors Nix file(s) with syntax errors"
    return 1
}

check_shell_syntax() {
    log_info "Checking Bash script syntax..."
    local errors=0
    local file

    while IFS= read -r -d '' file; do
        if ! head -n1 "$file" | grep -qE '^#!.*\bbash\b'; then
            continue
        fi
        if ! bash -n "$file"; then
            log_error "Shell syntax error in: $file"
            ((errors += 1))
        fi
    done < <(find . -type f -name '*.sh' -not -path './.git/*' -print0)

    if [[ $errors -eq 0 ]]; then
        log_success "All Bash scripts have valid syntax"
        return 0
    fi

    log_error "Found $errors Bash script(s) with syntax errors"
    return 1
}

check_host_configs() {
    log_info "Checking host configurations..."
    local errors=0
    local host
    local -a hosts=()
    mapfile -t hosts < <(discover_hosts)

    for host in "${hosts[@]}"; do
        local default_file="hosts/$host/default.nix"
        local hardware_file="hosts/$host/hardware.nix"
        local legacy_hardware_file="hosts/$host/hardware-configuration.nix"

        if [[ ! -f "$default_file" ]]; then
            log_error "Missing host config: $default_file"
            ((errors += 1))
            continue
        fi

        if grep -q '\./hardware\.nix' "$default_file" && [[ ! -f "$hardware_file" ]]; then
            log_error "$default_file imports ./hardware.nix but $hardware_file is missing"
            ((errors += 1))
        fi

        if [[ ! -f "$hardware_file" && ! -f "$legacy_hardware_file" ]]; then
            log_warning "No hardware file found for host '$host' (expected hardware.nix or hardware-configuration.nix)"
        fi

        if [[ ! -f "disko/$host.nix" ]]; then
            log_warning "Missing Disko config for host '$host': disko/$host.nix"
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "Host configuration checks passed"
        return 0
    fi

    log_error "Host configuration check failed with $errors error(s)"
    return 1
}

check_flake_outputs() {
    log_info "Evaluating flake outputs..."
    local errors=0
    local output cfg host

    if ! output="$(nix eval --raw '.#nixosConfigurations' --apply 'cfgs: builtins.concatStringsSep "\n" (builtins.attrNames cfgs)' 2>/dev/null)"; then
        log_error "Could not evaluate .#nixosConfigurations"
        return 1
    fi

    local -a nixos_configs=()
    while IFS= read -r cfg; do
        [[ -n "$cfg" ]] && nixos_configs+=("$cfg")
    done <<< "$output"

    if [[ ${#nixos_configs[@]} -eq 0 ]]; then
        log_error "No nixosConfigurations were found in flake outputs"
        return 1
    fi

    local -a hosts=()
    mapfile -t hosts < <(discover_hosts)

    for host in "${hosts[@]}"; do
        if ! array_contains "$host" "${nixos_configs[@]}"; then
            log_error "Host '$host' exists in hosts/ but is missing from nixosConfigurations"
            ((errors += 1))
        fi
        if ! array_contains "${host}-test" "${nixos_configs[@]}"; then
            log_warning "Missing test configuration '${host}-test' in nixosConfigurations"
        fi
    done

    for cfg in "${nixos_configs[@]}"; do
        if ! nix eval --raw ".#nixosConfigurations.${cfg}.config.system.build.toplevel" >/dev/null 2>&1; then
            log_error "Failed to evaluate nixosConfigurations.${cfg}.config.system.build.toplevel"
            ((errors += 1))
        fi
    done

    if output="$(nix eval --raw '.#diskoConfigurations' --apply 'cfgs: builtins.concatStringsSep "\n" (builtins.attrNames cfgs)' 2>/dev/null)"; then
        local -a disko_configs=()
        while IFS= read -r cfg; do
            [[ -n "$cfg" ]] && disko_configs+=("$cfg")
        done <<< "$output"

        for host in "${hosts[@]}"; do
            if ! array_contains "$host" "${disko_configs[@]}"; then
                log_warning "Host '$host' has no matching diskoConfigurations entry"
            fi
        done
    else
        log_warning "Could not evaluate .#diskoConfigurations"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Flake output evaluation successful"
        return 0
    fi

    log_error "Flake output evaluation failed with $errors error(s)"
    return 1
}

check_flake_check() {
    log_info "Running nix flake check (no build)..."
    local output

    if ! output="$(nix flake check --no-build --keep-going 2>&1)"; then
        printf '%s\n' "$output" | strip_nix_noise
        log_error "nix flake check failed"
        return 1
    fi

    log_success "nix flake check passed"
    return 0
}

check_flake_lock() {
    log_info "Checking flake.lock status..."

    if [[ ! -f "flake.lock" ]]; then
        log_warning "flake.lock missing (it will be created on first lock/update)"
        return 0
    fi

    if ! nix flake metadata --no-write-lock-file >/dev/null 2>&1; then
        log_error "flake metadata evaluation failed (lockfile may be invalid)"
        return 1
    fi

    if [[ $(find flake.lock -mtime +"$LOCK_AGE_DAYS" 2>/dev/null) ]]; then
        log_warning "flake.lock is over ${LOCK_AGE_DAYS} days old - consider running: nix flake update"
    else
        log_success "flake.lock is present and recent"
    fi

    return 0
}

# ── Validation Checks (Advisory) ─────────────────────────────────────────────

check_secrets() {
    log_info "Checking secrets hygiene..."
    local issues_before="$WARNING_COUNT"
    local matches file

    matches="$(
        grep -RInE --binary-files=without-match "$SECRET_PATTERNS" . \
            --exclude-dir=.git \
            --exclude='*.age' \
            --exclude='*.md' \
            --exclude='flake.lock' \
            --exclude='check.sh' \
            2>/dev/null || true
    )"

    if [[ -n "$matches" ]]; then
        echo "$matches"
        log_warning "Potential plaintext secrets found (review manually)"
    fi

    if [[ -f "secrets.nix" ]]; then
        local declared output
        output="$(
            nix eval --impure --raw --expr '
              let
                secrets = import ./secrets.nix;
              in
              builtins.concatStringsSep "\n" (builtins.attrNames secrets)
            ' 2>/dev/null || true
        )"

        while IFS= read -r file; do
            [[ -n "$file" ]] || continue
            if [[ -f "$file" || -f "secrets/$file" ]]; then
                continue
            fi
            log_warning "Secret declared in secrets.nix not found on disk: $file"
        done <<< "$output"
    fi

    if [[ -d "secrets" ]]; then
        while IFS= read -r -d '' file; do
            if [[ ! "$file" =~ \.age$ ]]; then
                log_warning "Plaintext file in secrets/ directory: $file"
            fi
        done < <(find secrets -type f -print0)
    fi

    if [[ "$issues_before" -eq "$WARNING_COUNT" ]]; then
        log_success "No obvious secret hygiene issues detected"
    fi

    return 0
}

check_broken_symlinks() {
    log_info "Checking for broken symlinks..."
    local links

    links="$(find . -xtype l -not -path './.git/*' -print || true)"
    if [[ -n "$links" ]]; then
        echo "$links"
        log_warning "Broken symlink(s) detected"
        return 0
    fi

    log_success "No broken symlinks found"
    return 0
}

check_git_status() {
    log_info "Checking git repository status..."
    local status

    status="$(git status --porcelain=v1 2>/dev/null || true)"
    if [[ -z "$status" ]]; then
        log_success "Git working tree is clean"
    else
        log_warning "Working tree has uncommitted changes"
        git --no-pager status --short
    fi

    return 0
}

# ── Main Execution ───────────────────────────────────────────────────────────

main() {
    echo "════════════════════════════════════════════════════════════════"
    echo "  NixOS Configuration Validation"
    echo "════════════════════════════════════════════════════════════════"
    echo

    local failed=0

    check_required_commands || ((failed += 1))
    echo

    check_repository_layout || ((failed += 1))
    echo

    check_merge_conflicts || ((failed += 1))
    echo

    check_nix_syntax || ((failed += 1))
    echo

    check_shell_syntax || ((failed += 1))
    echo

    check_host_configs || ((failed += 1))
    echo

    check_flake_outputs || ((failed += 1))
    echo

    check_flake_check || ((failed += 1))
    echo

    check_flake_lock || ((failed += 1))
    echo

    check_secrets
    echo

    check_broken_symlinks
    echo

    check_git_status
    echo

    echo "════════════════════════════════════════════════════════════════"

    if [[ "$failed" -eq 0 ]]; then
        log_success "All critical checks passed"
        if [[ "$WARNING_COUNT" -gt 0 ]]; then
            echo -e "${YELLOW}⚠${NC} $WARNING_COUNT warning(s) found (non-blocking)"
        fi
        echo
        echo "  Rebuild commands:"
        echo "    ${GREEN}nh os switch${NC}  or  ${GREEN}sudo nixos-rebuild switch --flake .#<host>${NC}"
        echo
        return 0
    fi

    log_error "$failed critical check(s) failed"
    if [[ "$WARNING_COUNT" -gt 0 ]]; then
        echo -e "${YELLOW}⚠${NC} $WARNING_COUNT warning(s) also found"
    fi
    echo
    echo "  Fix critical errors above before rebuilding."
    echo
    return 1
}

main "$@"
