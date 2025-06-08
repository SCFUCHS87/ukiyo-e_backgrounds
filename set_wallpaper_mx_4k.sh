#!/bin/bash

# Set the base wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Define resolution thresholds
RESOLUTION=$(xrandr | grep '*' | awk '{print $1}' | head -n1)
WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
HEIGHT=$(echo $RESOLUTION | cut -d'x' -f2)

# Decide on resolution suffix based on detected screen size
if [ "$WIDTH" -ge 3840 ]; then
    RES_SUFFIX="_4K_16x9.png"
else
    RES_SUFFIX="_16x9.png"
fi

# Get primary display
PRIMARY_DISPLAY=$(xrandr --query | grep " connected" | awk '{ print $1 }')

# Detect HDR (deep color or 10-bit)
HDR_ENABLED=$(xrandr --verbose | grep -A10 "^$PRIMARY_DISPLAY" | grep -i "10bit\|deep")

# Determine suffix for HDR
if [ -n "$HDR_ENABLED" ]; then
    HDR_SUFFIX="_HDR"
else
    HDR_SUFFIX=""
fi

# Available base filenames
WALLPAPERS=(
    "Plant_Zoo_Ukiyo-e_Linux_Solarized"
    "Dinosaurs_Ukiyo-e_Linux_Solarized"
    "Harry_Potter_Ukiyo-e_Linux_Solarized"
    "Outer_Space_Ukiyo-e_Linux_Solarized"
)

# Pick one at random
SELECTED_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
SELECTED="${WALLPAPERS[$SELECTED_INDEX]}${HDR_SUFFIX}${RES_SUFFIX}"
FULL_PATH="$WALLPAPER_DIR/$SELECTED"

# Set the wallpaper
echo "Setting wallpaper: $FULL_PATH"
feh --bg-scale "$FULL_PATH"
