#!/bin/bash

# Enhanced wallpaper resolution script with improved error handling and features
# Version 2.0

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Default configuration
DEFAULT_WALLPAPER_DIR="$HOME/Pictures/wallpapers"
WALLPAPER_DIR="${WALLPAPER_DIR:-$DEFAULT_WALLPAPER_DIR}"
LOG_FILE="${HOME}/.wallpaper_setter.log"
DRY_RUN=false
VERBOSE=false
FORCE_WALLPAPER_SETTER=""

# Base filenames of wallpapers
WALLPAPERS=(
    "Plant_Zoo_Ukiyo-e_Linux_Solarized"
    "Dinosaurs_Ukiyo-e_Linux_Solarized"
    "Harry_Potter_Ukiyo-e_Linux_Solarized"
    "Outer_Space_Ukiyo-e_Linux_Solarized"
)

# Supported wallpaper setters (in order of preference)
WALLPAPER_SETTERS=(
    "feh --bg-scale"
    "nitrogen --set-scaled"
    "gsettings set org.gnome.desktop.background picture-uri file://"
    "xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s"
)

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
    
    if [[ "$VERBOSE" == true ]] || [[ "$level" == "ERROR" ]]; then
        echo "[$level] $message" >&2
    fi
}

# Error handling function
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --print-only        Print the selected wallpaper path without setting it
    --dry-run          Show what would be done without actually doing it
    --verbose          Enable verbose output
    --wallpaper-dir    Specify custom wallpaper directory (default: ~/Pictures/wallpapers)
    --setter           Force specific wallpaper setter (feh, nitrogen, gnome, xfce)
    --help             Show this help message

Environment Variables:
    WALLPAPER_DIR      Custom wallpaper directory path

Examples:
    $0                                    # Set random wallpaper
    $0 --print-only                       # Show selected wallpaper path
    $0 --dry-run --verbose               # Preview with detailed output
    $0 --wallpaper-dir ~/custom/walls    # Use custom directory
    $0 --setter nitrogen                 # Force nitrogen as wallpaper setter

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --print-only)
                DRY_RUN=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --wallpaper-dir)
                WALLPAPER_DIR="$2"
                shift 2
                ;;
            --setter)
                FORCE_WALLPAPER_SETTER="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

# Check dependencies
check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    # Check for xrandr
    if ! command_exists xrandr; then
        error_exit "xrandr is required but not installed. Please install xorg-xrandr."
    fi
    
    # Check for at least one wallpaper setter
    local setter_found=false
    for setter in feh nitrogen gsettings xfconf-query; do
        if command_exists "$setter"; then
            setter_found=true
            log "INFO" "Found wallpaper setter: $setter"
            break
        fi
    done
    
    if [[ "$setter_found" == false ]]; then
        error_exit "No supported wallpaper setter found. Please install feh, nitrogen, or ensure you're running a supported desktop environment."
    fi
}

# Validate wallpaper directory
validate_wallpaper_dir() {
    log "INFO" "Validating wallpaper directory: $WALLPAPER_DIR"
    
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        error_exit "Wallpaper directory does not exist: $WALLPAPER_DIR"
    fi
    
    if [[ ! -r "$WALLPAPER_DIR" ]]; then
        error_exit "Cannot read wallpaper directory: $WALLPAPER_DIR"
    fi
    
    # Check if directory has any wallpaper files
    local wallpaper_count=$(find "$WALLPAPER_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | wc -l)
    if [[ "$wallpaper_count" -eq 0 ]]; then
        error_exit "No wallpaper files found in directory: $WALLPAPER_DIR"
    fi
    
    log "INFO" "Found $wallpaper_count wallpaper files in directory"
}

# Detect screen resolution with multi-monitor support
detect_resolution() {
    log "INFO" "Detecting screen resolution..."
    
    # Get primary display info
    local primary_output=$(xrandr --query | grep " connected primary" | cut -d' ' -f1)
    
    # If no primary display, get the first connected display
    if [[ -z "$primary_output" ]]; then
        primary_output=$(xrandr --query | grep " connected" | head -n1 | cut -d' ' -f1)
    fi
    
    if [[ -z "$primary_output" ]]; then
        error_exit "No connected displays found"
    fi
    
    log "INFO" "Primary display: $primary_output"
    
    # Get resolution for the primary display
    local resolution=$(xrandr --query | grep "^$primary_output" -A1 | grep '\*' | awk '{print $1}' | head -n1)
    
    if [[ -z "$resolution" ]]; then
        error_exit "Could not detect resolution for display: $primary_output"
    fi
    
    local width=$(echo "$resolution" | cut -d'x' -f1)
    local height=$(echo "$resolution" | cut -d'x' -f2)
    
    log "INFO" "Detected resolution: ${width}x${height}"
    
    echo "$width" "$height" "$primary_output"
}

# Enhanced HDR detection
detect_hdr() {
    local display="$1"
    log "INFO" "Detecting HDR capability for display: $display"
    
    # Multiple methods to detect HDR
    local hdr_detected=false
    
    # Method 1: Check for 10-bit or deep color in xrandr verbose output
    if xrandr --verbose | grep -A20 "^$display" | grep -qi "10bit\|deep"; then
        hdr_detected=true
        log "INFO" "HDR detected via xrandr deep color detection"
    fi
    
    # Method 2: Check for HDR-related properties
    if xrandr --verbose | grep -A20 "^$display" | grep -qi "hdr\|bt2020\|rec2020"; then
        hdr_detected=true
        log "INFO" "HDR detected via HDR/BT2020 properties"
    fi
    
    # Method 3: Check for high bit depth modes
    if xrandr --verbose | grep -A20 "^$display" | grep -E "depth.*[1-9][0-9]" | grep -qv "depth 24"; then
        hdr_detected=true
        log "INFO" "HDR detected via high bit depth"
    fi
    
    if [[ "$hdr_detected" == true ]]; then
        log "INFO" "HDR display detected"
        echo "_HDR"
    else
        log "INFO" "Standard display detected"
        echo ""
    fi
}

# Select wallpaper with fallback logic
select_wallpaper() {
    local width="$1"
    local height="$2"
    local hdr_suffix="$3"
    
    log "INFO" "Selecting wallpaper for ${width}x${height} with HDR suffix: '$hdr_suffix'"
    
    # Determine resolution suffix
    local res_suffix
    if [[ "$width" -ge 3840 ]]; then
        res_suffix="_4K_16x9.png"
    elif [[ "$width" -ge 2560 ]]; then
        res_suffix="_2K_16x9.png"
    else
        res_suffix="_16x9.png"
    fi
    
    # Select random wallpaper base
    local selected_index=$((RANDOM % ${#WALLPAPERS[@]}))
    local base_name="${WALLPAPERS[$selected_index]}"
    
    # Try different combinations in order of preference
    local attempts=(
        "${base_name}${hdr_suffix}${res_suffix}"
        "${base_name}${res_suffix}"
        "${base_name}${hdr_suffix}_16x9.png"
        "${base_name}_16x9.png"
        "${base_name}.png"
        "${base_name}.jpg"
    )
    
    for attempt in "${attempts[@]}"; do
        local full_path="$WALLPAPER_DIR/$attempt"
        if [[ -f "$full_path" ]]; then
            log "INFO" "Selected wallpaper: $attempt"
            echo "$full_path"
            return 0
        else
            log "DEBUG" "Wallpaper not found: $attempt"
        fi
    done
    
    # Fallback: find any wallpaper file
    log "WARN" "No matching wallpaper found, searching for any available wallpaper..."
    local fallback=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n1)
    
    if [[ -n "$fallback" ]]; then
        log "INFO" "Using fallback wallpaper: $(basename "$fallback")"
        echo "$fallback"
        return 0
    fi
    
    error_exit "No suitable wallpaper found in directory: $WALLPAPER_DIR"
}

# Determine best wallpaper setter
get_wallpaper_setter() {
    if [[ -n "$FORCE_WALLPAPER_SETTER" ]]; then
        case "$FORCE_WALLPAPER_SETTER" in
            feh)
                if command_exists feh; then
                    echo "feh --bg-scale"
                    return 0
                fi
                ;;
            nitrogen)
                if command_exists nitrogen; then
                    echo "nitrogen --set-scaled"
                    return 0
                fi
                ;;
            gnome)
                if command_exists gsettings; then
                    echo "gsettings set org.gnome.desktop.background picture-uri file://"
                    return 0
                fi
                ;;
            xfce)
                if command_exists xfconf-query; then
                    echo "xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s"
                    return 0
                fi
                ;;
        esac
        error_exit "Forced wallpaper setter '$FORCE_WALLPAPER_SETTER' is not available"
    fi
    
    # Auto-detect best setter
    for setter_cmd in "${WALLPAPER_SETTERS[@]}"; do
        local setter=$(echo "$setter_cmd" | cut -d' ' -f1)
        if command_exists "$setter"; then
            log "INFO" "Using wallpaper setter: $setter"
            echo "$setter_cmd"
            return 0
        fi
    done
    
    error_exit "No supported wallpaper setter found"
}

# Set wallpaper using the determined setter
set_wallpaper() {
    local wallpaper_path="$1"
    local setter_cmd="$2"
    
    log "INFO" "Setting wallpaper: $wallpaper_path"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "DRY RUN: Would execute: $setter_cmd \"$wallpaper_path\""
        echo "$wallpaper_path"
        return 0
    fi
    
    # Execute the setter command
    if eval "$setter_cmd \"$wallpaper_path\""; then
        log "INFO" "Wallpaper set successfully"
    else
        error_exit "Failed to set wallpaper using: $setter_cmd"
    fi
}

# Main function
main() {
    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    log "INFO" "Starting wallpaper setter script"
    
    # Parse arguments
    parse_args "$@"
    
    # Check dependencies
    check_dependencies
    
    # Validate wallpaper directory
    validate_wallpaper_dir
    
    # Detect resolution and display info
    read -r width height primary_display < <(detect_resolution)
    
    # Detect HDR
    hdr_suffix=$(detect_hdr "$primary_display")
    
    # Select wallpaper
    wallpaper_path=$(select_wallpaper "$width" "$height" "$hdr_suffix")
    
    # Handle print-only mode (legacy compatibility)
    if [[ "${1:-}" == "--print-only" ]]; then
        echo "$wallpaper_path"
        exit 0
    fi
    
    # Get wallpaper setter
    setter_cmd=$(get_wallpaper_setter)
    
    # Set wallpaper
    set_wallpaper "$wallpaper_path" "$setter_cmd"
    
    log "INFO" "Wallpaper setter script completed successfully"
}

# Execute main function with all arguments
main "$@"

