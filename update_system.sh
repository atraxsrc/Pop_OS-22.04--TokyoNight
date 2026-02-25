#!/bin/bash
set -eo pipefail

# ─────────────────────────────────────────────
#  Tokyo Night Dark palette
#  bg:      #1a1b26   fg:      #c0caf5
#  cyan:    #7dcfff   blue:    #7aa2f7
#  purple:  #bb9af7   green:   #9ece6a
#  yellow:  #e0af68   orange:  #ff9e64
#  red:     #f7768e   comment: #565f89
# ─────────────────────────────────────────────

# ANSI 256-color approximations of Tokyo Night Dark
CYAN='\033[38;2;125;207;255m'    # #7dcfff  – section headers
BLUE='\033[38;2;122;162;247m'    # #7aa2f7  – info / commands
PURPLE='\033[38;2;187;154;247m'  # #bb9af7  – highlights
GREEN='\033[38;2;158;206;106m'   # #9ece6a  – success
YELLOW='\033[38;2;224;175;104m'  # #e0af68  – warnings
ORANGE='\033[38;2;255;158;100m'  # #ff9e64  – skipped
RED='\033[38;2;247;118;142m'     # #f7768e  – errors
DIM='\033[38;2;86;95;137m'       # #565f89  – comments / dim text
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ────────────────────────────────────────────────────────────────────

print_header() {
    echo
    echo -e "${CYAN}${BOLD}┌─ $1 ${DIM}──────────────────────────────────────${RESET}"
}

print_success() { echo -e "  ${GREEN}✓ $1${RESET}"; }
print_info()    { echo -e "  ${BLUE}→ $1${RESET}"; }
print_warn()    { echo -e "  ${YELLOW}⚠ $1${RESET}"; }
print_skip()    { echo -e "  ${ORANGE}⊘ $1${RESET}"; }
print_error()   { echo -e "  ${RED}✗ $1${RESET}"; }
print_dim()     { echo -e "  ${DIM}$1${RESET}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── Update functions ───────────────────────────────────────────────────────────

update_system() {
    print_header "System Packages"

    if command_exists nala; then
        print_info "Package manager: nala"
        sudo nala update
        sudo nala upgrade --full -y
        sudo nala autoremove -y
        sudo nala clean
        print_success "Nala system update complete"

    elif command_exists apt; then
        print_info "Package manager: apt (nala not found)"
        sudo apt update
        sudo apt full-upgrade -y
        sudo apt autoremove -y
        sudo apt autoclean
        print_success "APT system update complete"

    else
        print_error "No supported package manager found — skipping"
        return 1
    fi
}

update_flatpak() {
    print_header "Flatpak"

    if ! command_exists flatpak; then
        print_skip "Flatpak not installed — skipping"
        return 0
    fi

    print_info "Running flatpak update..."
    local output exit_code
    output=$(flatpak update -y 2>&1) || true
    exit_code=$?
    echo "$output" | sed "s/^/  ${DIM}/${RESET}/"

    if echo "$output" | grep -q "Nothing to do"; then
        print_success "All Flatpaks are already up to date"
    elif [ "$exit_code" -eq 0 ]; then
        print_success "Flatpak updates applied"
        print_dim "(EOL runtime warnings above are normal)"
    else
        print_warn "Flatpak finished with warnings — see output above"
    fi
}

update_snap() {
    print_header "Snap"

    if ! command_exists snap; then
        print_skip "Snap not installed — skipping"
        return 0
    fi

    print_info "Running snap refresh..."
    local output
    output=$(sudo snap refresh 2>&1) || true
    echo "$output" | sed "s/^/  ${DIM}/${RESET}/"

    if echo "$output" | grep -q "All snaps up to date"; then
        print_success "All snaps are already up to date"
    else
        print_success "Snap updates applied"
    fi
}

# ── Main ───────────────────────────────────────────────────────────────────────

main() {
    local start_time end_time duration

    echo
    echo -e "${PURPLE}${BOLD}  ███████╗██╗   ██╗███████╗${RESET}"
    echo -e "${PURPLE}${BOLD}  ██╔════╝╚██╗ ██╔╝██╔════╝${RESET}"
    echo -e "${PURPLE}${BOLD}  ███████╗ ╚████╔╝ ███████╗${RESET}"
    echo -e "${PURPLE}${BOLD}  ╚════██║  ╚██╔╝  ╚════██║${RESET}"
    echo -e "${PURPLE}${BOLD}  ███████║   ██║   ███████║${RESET}"
    echo -e "${PURPLE}${BOLD}  ╚══════╝   ╚═╝   ╚══════╝${RESET}"
    echo -e "${DIM}  System Update — Pop!_OS / Cosmic${RESET}"
    echo -e "${DIM}  $(date '+%A %d %B %Y  %H:%M:%S')${RESET}"

    start_time=$(date +%s)

    update_system || {
        print_error "System package update failed — continuing with remaining tasks"
    }

    update_flatpak
    update_snap

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo
    echo -e "${CYAN}${BOLD}└─ All done ${DIM}──────────────────────────────────${RESET}"
    printf "   ${GREEN}✓ Completed in ${BOLD}%dm %ds${RESET}\n" \
        $((duration / 60)) $((duration % 60))
    echo
}

main
