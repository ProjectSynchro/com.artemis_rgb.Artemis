#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

MANIFEST_FILE="com.artemis_rgb.Artemis.yml"
BRANCH="test"

# Function to print error messages
error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error "$cmd is not installed. Please install $cmd and try again."
    fi
    echo "$cmd is installed."
}

# Check if required commands are installed
check_command "flatpak"
check_command "flatpak-builder"
check_command "yq"

# Extract required information from the manifest
if [ ! -f "$MANIFEST_FILE" ]; then
    error "Manifest file '$MANIFEST_FILE' not found."
fi

echo "Parsing manifest file '$MANIFEST_FILE' to determine required Flatpak packages and ID..."

RUNTIME=$(yq e '.runtime' "$MANIFEST_FILE")
RUNTIME_VERSION=$(yq e '.["runtime-version"]' "$MANIFEST_FILE")
SDK=$(yq e '.sdk' "$MANIFEST_FILE")
SDK_EXTENSIONS=$(yq e '.["sdk-extensions"][]' "$MANIFEST_FILE" 2>/dev/null || echo "")
FLATPAK_ID=$(yq e '.id' "$MANIFEST_FILE")

if [ -z "$RUNTIME" ] || [ -z "$RUNTIME_VERSION" ] || [ -z "$SDK" ] || [ -z "$FLATPAK_ID" ]; then
    error "Failed to extract required fields (runtime, runtime-version, sdk, id) from manifest."
fi

REQUIRED_FLATPAK_PACKAGES=(
    "$RUNTIME//$RUNTIME_VERSION"
    "$SDK//$RUNTIME_VERSION"
)

# Add SDK extensions if any
if [ -n "$SDK_EXTENSIONS" ]; then
    while IFS= read -r EXT; do
        REQUIRED_FLATPAK_PACKAGES+=("$EXT//$RUNTIME_VERSION")
    done <<< "$SDK_EXTENSIONS"
fi

# Function to check if a Flatpak package is installed
is_flatpak_installed() {
    local package="$1"
    flatpak info "$package" &> /dev/null
}

# Install missing Flatpak packages
for package in "${REQUIRED_FLATPAK_PACKAGES[@]}"; do
    if is_flatpak_installed "$package"; then
        echo "Flatpak package '$package' is already installed."
    else
        echo "Flatpak package '$package' is not installed. Installing..."
        flatpak install -y flathub "$package" || error "Failed to install $package"
    fi
done

# Update Flatpak repositories
echo "Updating Flatpak repositories..."
flatpak update -y || error "Failed to update Flatpak repositories"

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
rm -f "${FLATPAK_ID}.flatpak"
rm -rf build-dir repo-dir
mkdir build-dir repo-dir

# Build the Flatpak
echo "Building the Flatpak..."
flatpak-builder --ccache --force-clean --default-branch="$BRANCH" build-dir "$MANIFEST_FILE" --repo=repo-dir || error "flatpak-builder failed"

# Bundle the Flatpak
echo "Bundling the Flatpak..."
flatpak build-bundle repo-dir "${FLATPAK_ID}.flatpak" "$FLATPAK_ID" "$BRANCH" || error "flatpak build-bundle failed"

echo "Flatpak build and bundle completed successfully."

# Optionally, install the Flatpak
echo "Installing the Flatpak..."
flatpak install --user --reinstall -y "${FLATPAK_ID}.flatpak" || error "Flatpak installation failed"

echo "Flatpak installation completed successfully."
