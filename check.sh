#!/usr/bin/env bash
# =============================================================================
# NixOS Configuration Validation Script
# =============================================================================
# Performs pre-rebuild checks to catch common issues before building.
# Run before 'nixos-rebuild' or 'nh os switch' to validate changes.
#
# Checks:
#   • Nix syntax validation (all .nix files)
#   • Flake evaluation (without building)
#   • Hardware configuration exists for hosts
#   • No uncommitted secrets in repository
#   • Flake lock file is up-to-date
# =============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

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
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

# ── Validation Checks ────────────────────────────────────────────────────────

check_nix_syntax() {
    log_info "Checking Nix syntax..."
    local errors=0
    
    while IFS= read -r -d '' file; do
        if ! nix-instantiate --parse "$file" &>/dev/null; then
            log_error "Syntax error in: $file"
            ((errors+=1))
        fi
    done < <(find . -name "*.nix" -type f -print0)
    
    if [[ $errors -eq 0 ]]; then
        log_success "All Nix files have valid syntax"
        return 0
    else
        log_error "Found $errors file(s) with syntax errors"
        return 1
    fi
}

check_flake_evaluation() {
    log_info "Evaluating flake outputs..."

    if ! nix flake check --all-systems --no-build; then
        log_error "Flake evaluation failed"
        return 1
    else
        log_success "Flake evaluation successful"
        return 0
    fi
}

check_host_configs() {
    log_info "Checking host configurations..."
    local missing=0
    
    for host in desktop laptop; do
        if [[ ! -f "hosts/$host/default.nix" ]]; then
            log_error "Missing host config: hosts/$host/default.nix"
            ((missing+=1))
        fi

        if [[ ! -f "hosts/$host/hardware.nix" && ! -f "hosts/$host/hardware-configuration.nix" ]]; then
            log_warning "Missing hardware config: hosts/$host/hardware.nix (or hardware-configuration.nix)"
        fi
        
        if [[ ! -f "disko/$host.nix" ]]; then
            log_warning "Missing Disko config: disko/$host.nix"
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        log_success "All host configurations present"
        return 0
    else
        log_error "Missing $missing host configuration(s)"
        return 1
    fi
}

check_secrets() {
    log_info "Checking for uncommitted secrets..."
    local found=0

    # High-signal secret patterns (avoid noisy keyword-only matches)
    local matches
    matches="$(
        git grep -nEI \
            '(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{82}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY-----)' \
            -- \
            . \
            ":(exclude)**/*.age" \
            ":(exclude)**/*.md" \
            ":(exclude)check.sh" \
            || true
    )"

    if [[ -n "$matches" ]]; then
        echo "$matches"
        log_warning "Potential plaintext secrets found in tracked files (review manually)"
        ((found+=1))
    fi

    # Check for .age files that should be encrypted
    while IFS= read -r -d '' file; do
        if [[ ! "$file" =~ \.age$ ]]; then
            log_warning "Plaintext secret file detected: $file"
            ((found+=1))
        fi
    done < <(find secrets -type f -print0 2>/dev/null || true)
    
    if [[ $found -eq 0 ]]; then
        log_success "No obvious secret issues detected"
    fi
    
    return 0
}

check_flake_lock() {
    log_info "Checking flake.lock status..."
    
    if [[ ! -f "flake.lock" ]]; then
        log_warning "flake.lock missing (will be created on first build)"
        return 0
    fi
    
    # Check if flake.lock is outdated (older than 30 days)
    if [[ $(find flake.lock -mtime +30 2>/dev/null) ]]; then
        log_warning "flake.lock is over 30 days old - consider running: nix flake update"
    else
        log_success "flake.lock is up-to-date"
    fi
    
    return 0
}

check_git_status() {
    log_info "Checking git repository status..."
    
    if git diff --quiet && git diff --cached --quiet; then
        log_success "No uncommitted changes"
    else
        log_warning "You have uncommitted changes - consider committing before rebuild"
        git status --short
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
    
    check_nix_syntax || ((failed++))
    echo
    
    check_host_configs || ((failed++))
    echo
    
    check_flake_evaluation || ((failed++))
    echo
    
    check_secrets
    echo
    
    check_flake_lock
    echo
    
    check_git_status
    echo
    
    echo "════════════════════════════════════════════════════════════════"
    
    if [[ $failed -eq 0 ]]; then
        log_success "All critical checks passed!"
        echo
        echo "  You can safely rebuild with:"
        echo "    ${GREEN}nh os switch${NC}  or  ${GREEN}sudo nixos-rebuild switch --flake .#<host>${NC}"
        echo
        return 0
    else
        log_error "$failed critical check(s) failed"
        echo
        echo "  Fix the errors above before rebuilding."
        echo
        return 1
    fi
}

main "$@"
