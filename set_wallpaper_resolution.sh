#!/bin/bash

# Set the base wallpaper directory (case-sensitive)
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Detect screen resolution
RESOLUTION=$(xrandr | grep '*' | awk '{print $1}' | head -n1)
WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)

# Choose resolution suffix
if [ "$WIDTH" -ge 3840 ]; then
    RES_SUFFIX="_4K_16x9.png"
else
    RES_SUFFIX="_16x9.png"
fi

# Get the primary display name
PRIMARY_DISPLAY=$(xrandr --query | grep " connected" | awk '{ print $1 }')

# Detect HDR (10bit or deep color modes)
HDR_ENABLED=$(xrandr --verbose | grep -A10 "^$PRIMARY_DISPLAY" | grep -i "10bit\|deep")

# Choose HDR suffix
if [ -n "$HDR_ENABLED" ]; then
    HDR_SUFFIX="_HDR"
    echo "HDR detected. Using HDR wallpapers."
else
    HDR_SUFFIX=""
    echo "No HDR detected. Using standard wallpapers."
fi

# Base filenames of wallpapers
WALLPAPERS=(
    "Plant_Zoo_Ukiyo-e_Linux_Solarized"
    "Dinosaurs_Ukiyo-e_Linux_Solarized"
    "Harry_Potter_Ukiyo-e_Linux_Solarized"
    "Outer_Space_Ukiyo-e_Linux_Solarized"
)

# Select a random wallpaper
SELECTED_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
SELECTED="${WALLPAPERS[$SELECTED_INDEX]}${HDR_SUFFIX}${RES_SUFFIX}"
FULL_PATH="$WALLPAPER_DIR/$SELECTED"

# Set the wallpaper
echo "Setting wallpaper: $FULL_PATH"
feh --bg-scale "$FULL_PATH"

# Add this at the very end of set_wallpaper_resolution.sh
if [[ "$1" == "--print-only" ]]; then
    echo "$FULL_PATH"
    exit 0
fi

