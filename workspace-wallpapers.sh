#!/bin/bash

# Workspace Wallpaper Manager for Ubuntu GNOME
# Automatically switches wallpapers when changing workspaces

# Get some dark wallpapers from the system
CURRENT_WALLPAPER=$(gsettings get org.gnome.desktop.background picture-uri-dark | tr -d "'")

# Configuration - Set your wallpapers here (0-indexed)
declare -A WALLPAPERS

# Base directory for wallpapers (change this to your wallpaper location)
BASE_DIR="${HOME}/Documents/desktops"

# Your 11 workspaces with FRESHLY SCRAPED ultra-dark wallpapers
WALLPAPERS[0]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_003.jpg"  # 98.0% dark
WALLPAPERS[1]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_005.jpg"  # 97.2% dark
WALLPAPERS[2]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_004.jpg"  # 96.2% dark
WALLPAPERS[3]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_010.jpg"  # 95.9% dark
WALLPAPERS[4]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_009.jpg"  # 94.0% dark
WALLPAPERS[5]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_007.jpg"  # 93.6% dark
WALLPAPERS[6]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_001.jpg"  # 90.7% dark
WALLPAPERS[7]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_012.jpg"  # 90.5% dark
WALLPAPERS[8]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_002.jpg"  # 88.7% dark
WALLPAPERS[9]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_015.jpg"  # 88.1% dark
WALLPAPERS[10]="file://${BASE_DIR}/scraped-wallpapers/dark_wallhaven_011.jpg" # 84.1% dark

# You can customize these paths to your own images
# Just make sure to use the file:// prefix

# Function to get current workspace using wmctrl
get_current_workspace() {
    wmctrl -d | grep '\*' | cut -d' ' -f1
}

# Function to set wallpaper with force refresh
set_wallpaper() {
    local wallpaper="$1"
    
    # Clear any cached wallpaper first
    gsettings set org.gnome.desktop.background picture-uri ""
    gsettings set org.gnome.desktop.background picture-uri-dark ""
    
    # Small delay to ensure clearing takes effect
    sleep 0.1
    
    # Now set the new wallpaper (set both light and dark mode)
    gsettings set org.gnome.desktop.background picture-uri "$wallpaper"
    gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper"
    
    # Force the picture-options to ensure proper display
    gsettings set org.gnome.desktop.background picture-options 'scaled'
    
    # Extract filename for display
    local filename=$(echo "$wallpaper" | sed 's|.*/||' | sed 's|\..*||')
    echo "✓ Set wallpaper: $filename"
}

# Check if wmctrl is installed
if ! command -v wmctrl &> /dev/null; then
    echo "Error: wmctrl is not installed"
    echo "Install it with: sudo apt install wmctrl"
    exit 1
fi

# Main functions
if [ "$1" == "--daemon" ] || [ "$1" == "-d" ]; then
    echo "🚀 Workspace Wallpaper Daemon Started"
    echo "📍 Monitoring workspace changes..."
    echo "   Press Ctrl+C to stop"
    echo ""
    
    LAST_WORKSPACE=$(get_current_workspace)
    
    # Set initial wallpaper
    if [ -n "${WALLPAPERS[$LAST_WORKSPACE]}" ]; then
        set_wallpaper "${WALLPAPERS[$LAST_WORKSPACE]}"
    fi
    
    # Store current wallpaper for each workspace to detect changes
    declare -A CURRENT_WALLPAPER
    
    while true; do
        CURRENT_WORKSPACE=$(get_current_workspace)
        
        if [ "$CURRENT_WORKSPACE" != "$LAST_WORKSPACE" ]; then
            echo "→ Switched to Workspace $((CURRENT_WORKSPACE + 1))"
            
            if [ -n "${WALLPAPERS[$CURRENT_WORKSPACE]}" ]; then
                set_wallpaper "${WALLPAPERS[$CURRENT_WORKSPACE]}"
                CURRENT_WALLPAPER[$CURRENT_WORKSPACE]="${WALLPAPERS[$CURRENT_WORKSPACE]}"
            else
                echo "ℹ Using default wallpaper for Workspace $((CURRENT_WORKSPACE + 1))"
            fi
            
            LAST_WORKSPACE=$CURRENT_WORKSPACE
        else
            # Even if we haven't switched, verify the correct wallpaper is set
            # This prevents old wallpapers from "leaking" back
            if [ -n "${WALLPAPERS[$CURRENT_WORKSPACE]}" ]; then
                ACTUAL_WALLPAPER=$(gsettings get org.gnome.desktop.background picture-uri-dark | tr -d "'")
                EXPECTED_WALLPAPER="${WALLPAPERS[$CURRENT_WORKSPACE]}"
                
                if [ "$ACTUAL_WALLPAPER" != "$EXPECTED_WALLPAPER" ]; then
                    echo "⚠ Correcting wallpaper for Workspace $((CURRENT_WORKSPACE + 1))"
                    set_wallpaper "${WALLPAPERS[$CURRENT_WORKSPACE]}"
                fi
            fi
        fi
        
        sleep 0.2
    done
    
elif [ "$1" == "--test" ] || [ "$1" == "-t" ]; then
    echo "🎨 Testing workspace detection..."
    CURRENT=$(get_current_workspace)
    echo "Current workspace: $((CURRENT + 1))"
    
    if [ -n "${WALLPAPERS[$CURRENT]}" ]; then
        echo "Wallpaper configured: ${WALLPAPERS[$CURRENT]}"
    else
        echo "No custom wallpaper for this workspace"
    fi
    
    echo ""
    echo "📋 Configured wallpapers:"
    for i in {0..10}; do
        if [ -n "${WALLPAPERS[$i]}" ]; then
            filename=$(echo "${WALLPAPERS[$i]}" | sed 's|.*/||' | sed 's|\..*||')
            echo "  Workspace $((i + 1)): $filename"
        fi
    done
    
elif [ "$1" == "--set-current" ] || [ "$1" == "-s" ]; then
    CURRENT=$(get_current_workspace)
    if [ -n "${WALLPAPERS[$CURRENT]}" ]; then
        echo "Setting wallpaper for Workspace $((CURRENT + 1))..."
        set_wallpaper "${WALLPAPERS[$CURRENT]}"
    else
        echo "No wallpaper configured for Workspace $((CURRENT + 1))"
    fi
    
else
    echo "Workspace Wallpaper Manager"
    echo ""
    echo "Usage:"
    echo "  $0 --daemon    (-d)  Start monitoring workspace changes"
    echo "  $0 --test      (-t)  Test workspace detection"
    echo "  $0 --set-current (-s) Set wallpaper for current workspace"
    echo ""
    echo "To run at startup:"
    echo "  1. Copy the .desktop file to autostart:"
    echo "     cp workspace-wallpapers.desktop ~/.config/autostart/"
    echo "  2. Or add to Startup Applications:"
    echo "     $PWD/$0 --daemon"
    echo ""
    echo "To customize wallpapers:"
    echo "  Edit this script and modify the WALLPAPERS array"
fi