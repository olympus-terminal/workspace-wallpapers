#!/bin/bash

# Fast Workspace Wallpaper Manager using D-Bus signals
# Responds instantly to workspace changes without polling

# Configuration
declare -A WALLPAPERS
BASE_DIR="${HOME}/Documents/desktops"

# Enhanced wallpapers with +20% contrast and -20% brightness
WALLPAPERS[0]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_180-degree_view_of_dark_futuristic_metropolis_trans_2e28d41a-3fb6-4504-95eb-e942e2b3a1df-topaz-lighting-upscale-1.6x.png"
WALLPAPERS[1]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_180-degree_view_of_dark_futuristic_metropolis_trans_eb4fc490-67b9-4108-9857-200c7fdd3db2-topaz-lighting-upscale-1.6x.png"
WALLPAPERS[2]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Dark_futuristic_biodome_cities_under_alien_jungle_c_52d40d22-28ff-4450-a4c5-f787358c339c-topaz-lighting-upscale-1.6x.png"
WALLPAPERS[3]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Dark_rainy_futuristic_cityscape_with_massive_vertic_9afd1f9a-db7a-44fa-bf7e-708eafdc0d0a-topaz-lighting-upscale-1.6x.png"
WALLPAPERS[4]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Dark_rainy_futuristic_cityscape_with_massive_vertic_df5b4239-c06b-465f-9d7f-a2dce77d9cae.png"
WALLPAPERS[5]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_sprawling_megacity_one_of_the_last_cities_of_humans_caf6c0a5-21af-4a40-9ed7-a443197b7aff.png"
WALLPAPERS[6]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Towering_megacity_with_cascading_jungle_waterfalls__0a4d6338-ecf7-4f7d-b01b-ea3105bd4be2.png"
WALLPAPERS[7]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Towering_megacity_with_cascading_jungle_waterfalls__3aa1efa2-9745-4cf8-b723-ee009bdf2afe-topaz-lighting-upscale-1.6x.png"
WALLPAPERS[8]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Towering_megacity_with_cascading_jungle_waterfalls__3efac9d2-1007-476f-8dae-961846682e31.png"
WALLPAPERS[9]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Towering_megacity_with_cascading_jungle_waterfalls__848c23d8-215b-42fb-90da-9ff5215cd537-topaz-lighting-upscale-1.6x.png"
WALLPAPERS[10]="file://${BASE_DIR}/MJ7-Topaz/enhanced/u4265883636_Towering_megacity_with_cascading_jungle_waterfalls__d4fb0d35-f061-442f-80eb-843c0ffba1c5-topaz-lighting-upscale-1.6x.png"

# Fast wallpaper setter with minimal delay to prevent black screens
set_wallpaper_fast() {
    local wallpaper="$1"
    # Set both URIs with a tiny delay to ensure proper rendering
    gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper"
    gsettings set org.gnome.desktop.background picture-uri "$wallpaper"

    local filename=$(basename "$wallpaper")
    filename="${filename%.jpg}"
    filename="${filename%.png}"
    echo "✓ Set wallpaper: $filename"
}

# Get current workspace more efficiently
get_workspace_fast() {
    # Use wmctrl for reliable workspace detection
    wmctrl -d 2>/dev/null | grep '\*' | cut -d' ' -f1
}

# Monitor workspace changes using D-Bus signals
monitor_with_dbus() {
    echo "🚀 Fast Workspace Wallpaper Daemon Started"
    echo "⚡ Using D-Bus signals for instant response"
    echo "   Press Ctrl+C to stop"
    echo ""
    
    # Set initial wallpaper
    CURRENT=$(get_workspace_fast)
    if [ -n "${WALLPAPERS[$CURRENT]}" ]; then
        set_wallpaper_fast "${WALLPAPERS[$CURRENT]}"
    fi
    
    # Monitor workspace switch signals
    gdbus monitor --session --dest org.gnome.Shell --object-path /org/gnome/Shell | \
    while read -r line; do
        # Check if workspace changed
        if [[ "$line" == *"workspace"* ]] || [[ "$line" == *"active-workspace"* ]]; then
            NEW_WORKSPACE=$(get_workspace_fast)
            if [ -n "${WALLPAPERS[$NEW_WORKSPACE]}" ]; then
                echo "→ Switched to Workspace $((NEW_WORKSPACE + 1))"
                set_wallpaper_fast "${WALLPAPERS[$NEW_WORKSPACE]}" &
            fi
        fi
    done
}

# Alternative: Ultra-fast polling version (if D-Bus doesn't work well)
monitor_fast_polling() {
    echo "🚀 Fast Workspace Wallpaper Daemon Started"
    echo "⚡ Using optimized polling (50ms intervals)"
    echo "   Press Ctrl+C to stop"
    echo ""
    
    LAST_WORKSPACE=$(get_workspace_fast)
    
    # Set initial wallpaper
    if [ -n "${WALLPAPERS[$LAST_WORKSPACE]}" ]; then
        set_wallpaper_fast "${WALLPAPERS[$LAST_WORKSPACE]}"
    fi
    
    while true; do
        CURRENT_WORKSPACE=$(get_workspace_fast)
        
        if [ "$CURRENT_WORKSPACE" != "$LAST_WORKSPACE" ]; then
            echo "→ Switched to Workspace $((CURRENT_WORKSPACE + 1))"
            
            if [ -n "${WALLPAPERS[$CURRENT_WORKSPACE]}" ]; then
                set_wallpaper_fast "${WALLPAPERS[$CURRENT_WORKSPACE]}" &
            fi
            
            LAST_WORKSPACE=$CURRENT_WORKSPACE
        fi
        
        sleep 0.05  # 50ms polling for near-instant response
    done
}

# Main execution
case "$1" in
    --daemon|-d)
        monitor_with_dbus
        ;;
    --fast-poll|-f)
        monitor_fast_polling
        ;;
    --test|-t)
        echo "Testing workspace detection..."
        CURRENT=$(get_workspace_fast)
        echo "Current workspace: $((CURRENT + 1))"
        
        if [ -n "${WALLPAPERS[$CURRENT]}" ]; then
            echo "Wallpaper: ${WALLPAPERS[$CURRENT]}"
        else
            echo "No custom wallpaper for this workspace"
        fi
        ;;
    --set-current|-s)
        CURRENT=$(get_workspace_fast)
        if [ -n "${WALLPAPERS[$CURRENT]}" ]; then
            echo "Setting wallpaper for Workspace $((CURRENT + 1))..."
            set_wallpaper_fast "${WALLPAPERS[$CURRENT]}"
        else
            echo "No wallpaper configured for Workspace $((CURRENT + 1))"
        fi
        ;;
    *)
        echo "Fast Workspace Wallpaper Manager"
        echo ""
        echo "Usage:"
        echo "  $0 --daemon      (-d)  Use D-Bus signals (instant response)"
        echo "  $0 --fast-poll   (-f)  Use fast polling (50ms intervals)"
        echo "  $0 --test        (-t)  Test workspace detection"
        echo "  $0 --set-current (-s)  Set wallpaper for current workspace"
        echo ""
        echo "The --daemon mode is recommended for best performance."
        ;;
esac