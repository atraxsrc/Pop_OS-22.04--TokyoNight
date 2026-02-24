#!/bin/bash

# ================================================
# Universal System Updater (Nala + Flatpak + Snap)
# ================================================

set -eo pipefail

# ------------------- Helpers -------------------
print_color() {
    case "$1" in
        "green")  echo -e "\033[0;32m$2\033[0m" ;;
        "red")    echo -e "\033[0;31m$2\033[0m" ;;
        "yellow") echo -e "\033[0;33m$2\033[0m" ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------- System Update -------------------
update_system() {
    print_color "yellow" "Updating system packages..."

    if command_exists nala; then
        sudo nala update
        sudo nala full-upgrade -y          # ← This is the important change
        sudo nala autoremove -y
        sudo nala clean
        print_color "green" "Nala system update complete"
    elif command_exists apt; then
        # Modern fallback using 'apt' (cleaner output than apt-get)
        sudo apt update
        sudo apt full-upgrade -y
        sudo apt autoremove -y
        sudo apt autoclean
        print_color "green" "APT system update complete"
    else
        print_color "red" "No supported package manager found. Skipping system update."
        return 1
    fi
}

# ------------------- Flatpak Update -------------------
update_flatpak() {
    if command_exists flatpak; then
        print_color "yellow" "Updating Flatpak apps..."

        local output
        output=$(flatpak update -y 2>&1)
        local exit_code=$?

        echo "$output"

        if echo "$output" | grep -q "Nothing to do"; then
            print_color "green" "All Flatpaks are up to date"
        elif [ "$exit_code" -eq 0 ]; then
            print_color "green" "Flatpak updates applied (warnings for EOL runtimes are normal)"
        else
            print_color "yellow" "Flatpak update completed with issues (warnings/errors shown above are often normal for EOL runtimes)"
        fi
    else
        print_color "yellow" "Flatpak not found. Skipping."
    fi
}

# ------------------- Snap Update -------------------
update_snap() {
    if command_exists snap; then
        print_color "yellow" "Updating Snap packages..."

        local snap_output
        snap_output=$(sudo snap refresh 2>&1)
        echo "$snap_output"

        if echo "$snap_output" | grep -q "All snaps up to date"; then
            print_color "green" "All snaps are up to date"
        else
            print_color "green" "Snap updates applied"
        fi
    else
        print_color "yellow" "Snap not found. Skipping."
    fi
}

# ------------------- Main -------------------
main() {
    local start_time end_time duration

    start_time=$(date +%s)

    print_color "green" "=== Starting system update ==="
    print_color "yellow" "Date: $(date)"

    update_system
    update_flatpak
    update_snap

    print_color "green" "=== System update completed ==="

    end_time=$(date +%s)
    duration=$((end_time - start_time))
    printf "~ took %dm%ds\n" $((duration / 60)) $((duration % 60))
}

# Run it
main
