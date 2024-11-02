#!/usr/bin/env bash

set -euo pipefail  # Exit on error, undefined variable, and pipe errors

# ---------------------------
# Configuration
# ---------------------------

# Paths and files
MANIFEST_FILE="com.artemis_rgb.Artemis.yml"  # Path to your Flatpak manifest YAML file

# ---------------------------
# Functions
# ---------------------------

# Function to print error messages and exit
error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error "'$cmd' is not installed. Please install it and try again."
    fi
}

# ---------------------------
# Parse Command Line Arguments
# ---------------------------

# Defaults
UPDATE_TARGET="all"

usage() {
    echo "Usage: $(basename "$0") [-v] [-a] [-p] [-d]"
    echo
    echo "Options:"
    echo "  -v    Verbose output"
    echo "  -a    Update Artemis NuGet sources"
    echo "  -p    Update Artemis.Plugins NuGet sources"
    echo "  -d    Update .NET runtime sources (TODO)"
    exit 1
}

while getopts "vapd" OPTION; do
    case $OPTION in
        v)
            set -x
            ;;
        a)
            UPDATE_TARGET="a"
            ;;
        p)
            UPDATE_TARGET="p"
            ;;
        d)
            UPDATE_TARGET="d"
            ;;
        *)
            usage
            ;;
    esac
done

# ---------------------------
# Check for Required Tools
# ---------------------------

echo "Checking for required tools..."

REQUIRED_TOOLS=(
    "git"
    "python"
    "yq"
)

for cmd in "${REQUIRED_TOOLS[@]}"; do
    check_command "$cmd"
done

echo "All required tools are installed."

# ---------------------------
# Extract Variables from Manifest
# ---------------------------

echo "Extracting variables from manifest..."

# Ensure the manifest file exists
if [[ ! -f "$MANIFEST_FILE" ]]; then
    error "Manifest file '$MANIFEST_FILE' not found."
fi

# Extract the .NET version
DOTNET_VERSION=$(yq '.sdk-extensions[] | select(. == "*dotnet*") | sub(".*dotnet", "")' "$MANIFEST_FILE")
if [[ -z "$DOTNET_VERSION" ]]; then
    error "Failed to extract .NET version from manifest."
fi
echo ".NET version: $DOTNET_VERSION"

# Extract the Freedesktop runtime version
FREEDESKTOP_VERSION=$(yq '.runtime-version' "$MANIFEST_FILE" | tr -d "'")
if [[ -z "$FREEDESKTOP_VERSION" ]]; then
    error "Failed to extract Freedesktop runtime version from manifest."
fi
echo "Freedesktop runtime version: $FREEDESKTOP_VERSION"

# Extract the Artemis commit hash
ARTEMIS_HASH=$(yq '.modules[] | select(.name == "artemis") | .sources[] | select(.url == "https://github.com/Artemis-RGB/Artemis.git") | .commit' "$MANIFEST_FILE")
if [[ -z "$ARTEMIS_HASH" ]]; then
    error "Failed to extract Artemis commit hash from manifest."
fi
echo "Artemis commit hash: $ARTEMIS_HASH"

# Extract the Artemis.Plugins commit hash
ARTEMIS_PLUGINS_HASH=$(yq '.modules[] | select(.name == "artemis") | .sources[] | select(.url == "https://github.com/Artemis-RGB/Artemis.Plugins.git") | .commit' "$MANIFEST_FILE")
if [[ -z "$ARTEMIS_PLUGINS_HASH" ]]; then
    error "Failed to extract Artemis.Plugins commit hash from manifest."
fi
echo "Artemis.Plugins commit hash: $ARTEMIS_PLUGINS_HASH"

# ---------------------------
# Create Temporary Directory
# ---------------------------

echo "Creating temporary directory..."
TEMP_DIR=$(mktemp -d -p .)
if [[ ! -d "$TEMP_DIR" ]]; then
    error "Failed to create temporary directory."
fi
echo "Temporary directory created at '$TEMP_DIR'."

# ---------------------------
# Update Sources Functions
# ---------------------------

update_artemis_sources() {
    echo "Updating Artemis sources..."

    # Backup existing sources file if it exists
    if [[ -f artemis-sources.json ]]; then
        mv artemis-sources.json artemis-sources.bak
        echo "Backed up existing 'artemis-sources.json' to 'artemis-sources.bak'."
    fi

    # Clone the Artemis repository
    git clone https://github.com/Artemis-RGB/Artemis.git --recurse "$TEMP_DIR/Artemis" || error "Failed to clone Artemis repository."
    git -C "$TEMP_DIR/Artemis" checkout "$ARTEMIS_HASH" || error "Failed to checkout commit '$ARTEMIS_HASH'."

    # Find the project file
    readarray -d '' projects < <(find "$TEMP_DIR/Artemis" -type f -name "Artemis.UI.Linux.csproj" -print0)
    if [[ ${#projects[@]} -eq 0 ]]; then
        error "No 'Artemis.UI.Linux.csproj' file found."
    fi

    # Generate sources using flatpak-dotnet-generator.py
    echo "Generating 'artemis-sources.json'..."
    ./builder-tools/dotnet/flatpak-dotnet-generator.py \
        -d "$DOTNET_VERSION" \
        -f "$FREEDESKTOP_VERSION" \
        -r linux-x64 \
        artemis-sources.json "${projects[@]}" || error "Failed to generate 'artemis-sources.json'."
    echo "'artemis-sources.json' generated successfully."
}

update_artemis_plugins_sources() {
    echo "Updating Artemis.Plugins sources..."

    # Backup existing sources file if it exists
    if [[ -f artemis-plugins-sources.json ]]; then
        mv artemis-plugins-sources.json artemis-plugins-sources.bak
        echo "Backed up existing 'artemis-plugins-sources.json' to 'artemis-plugins-sources.bak'."
    fi

    # Clone the Artemis.Plugins repository
    git clone https://github.com/Artemis-RGB/Artemis.Plugins.git --recurse "$TEMP_DIR/Artemis.Plugins" || error "Failed to clone Artemis.Plugins repository."
    git -C "$TEMP_DIR/Artemis.Plugins" checkout "$ARTEMIS_PLUGINS_HASH" || error "Failed to checkout commit '$ARTEMIS_PLUGINS_HASH'."

    # Find all project files
    readarray -d '' projects < <(find "$TEMP_DIR/Artemis.Plugins" -type f -name "*.csproj" -print0)
    if [[ ${#projects[@]} -eq 0 ]]; then
        error "No '.csproj' files found in Artemis.Plugins."
    fi

    # Generate sources using flatpak-dotnet-generator.py
    echo "Generating 'artemis-plugins-sources.json'..."
    ./builder-tools/dotnet/flatpak-dotnet-generator.py \
        -d "$DOTNET_VERSION" \
        -f "$FREEDESKTOP_VERSION" \
        -r linux-x64 \
        artemis-plugins-sources.json "${projects[@]}" || error "Failed to generate 'artemis-plugins-sources.json'."
    echo "'artemis-plugins-sources.json' generated successfully."
}

update_dotnet_runtime_sources() {
    echo "Updating .NET runtime sources..."
    # TODO: Implement the update for .NET runtime sources
    echo "This feature is not implemented yet."
}

# ---------------------------
# Update Sources Based on Selection
# ---------------------------

case "$UPDATE_TARGET" in
    all)
        update_artemis_sources
        update_artemis_plugins_sources
        update_dotnet_runtime_sources
        ;;
    a)
        update_artemis_sources
        ;;
    p)
        update_artemis_plugins_sources
        ;;
    d)
        update_dotnet_runtime_sources
        ;;
    *)
        usage
        ;;
esac

# ---------------------------
# Clean Up
# ---------------------------

echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
echo "Temporary directory '$TEMP_DIR' removed."
echo "Temporary files cleaned up."

# ---------------------------
# Completion Message
# ---------------------------

echo "Source update completed successfully."
