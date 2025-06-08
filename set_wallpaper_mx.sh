#!/bin/bash

# Set paths for wallpapers (adjust to your folder)
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPERS_NONHDR=(
    "$WALLPAPER_DIR/Plant_Zoo_Ukiyo-e_Linux_Solarized_16x9.png"
    "$WALLPAPER_DIR/Dinosaurs_Ukiyo-e_Linux_Solarized_16x9.png"
    "$WALLPAPER_DIR/Harry_Potter_Ukiyo-e_Linux_Solarized_16x9.png"
    "$WALLPAPER_DIR/Outer_Space_Ukiyo-e_Linux_Solarized_16x9.png"
)
WALLPAPERS_HDR=(
    "$WALLPAPER_DIR/Plant_Zoo_Ukiyo-e_Linux_Solarized_HDR_16x9.png"
    "$WALLPAPER_DIR/Dinosaurs_Ukiyo-e_Linux_Solarized_HDR_16x9.png"
    "$WALLPAPER_DIR/Harry_Potter_Ukiyo-e_Linux_Solarized_HDR_16x9.png"
    "$WALLPAPER_DIR/Outer_Space_Ukiyo-e_Linux_Solarized_HDR_16x9.png"
)

# Get the primary display name
PRIMARY_DISPLAY=$(xrandr --query | grep " connected" | awk '{ print $1 }')

# Check for HDR capability (10bit or deep color modes)
HDR_ENABLED=$(xrandr --verbose | grep -A10 "^$PRIMARY_DISPLAY" | grep -i "10bit\|deep")

# Choose the wallpaper set
if [ -n "$HDR_ENABLED" ]; then
    echo "HDR detected (X11). Using HDR wallpapers."
    WALLPAPERS=("${WALLPAPERS_HDR[@]}")
else
    echo "No HDR detected (X11). Using standard wallpapers."
    WALLPAPERS=("${WALLPAPERS_NONHDR[@]}")
fi

# Randomly select one of the wallpapers
SELECTED_WALLPAPER="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"

# Set wallpaper using feh
feh --bg-scale "$SELECTED_WALLPAPER"
