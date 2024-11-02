#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

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

# Check if flatpak is installed
check_command "flatpak"

# Check if flatpak-builder is installed
check_command "flatpak-builder"

# Define required Flatpak packages

REQUIRED_RUNTIME_VERSION="23.08"

REQUIRED_FLATPAK_PACKAGES=(
    "org.freedesktop.Platform//$REQUIRED_RUNTIME_VERSION"
    "org.freedesktop.Sdk//$REQUIRED_RUNTIME_VERSION"
    "org.freedesktop.Sdk.Extension.dotnet7//$REQUIRED_RUNTIME_VERSION"
)

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
rm -f com.artemis_rgb.Artemis.flatpak
rm -rf build-dir repo-dir
mkdir build-dir repo-dir

# Build the Flatpak
echo "Building the Flatpak..."
flatpak-builder --ccache --force-clean --default-branch="$BRANCH" build-dir com.artemis_rgb.Artemis.yml --repo=repo-dir || error "flatpak-builder failed"

# Bundle the Flatpak
echo "Bundling the Flatpak..."
flatpak build-bundle repo-dir com.artemis_rgb.Artemis.flatpak com.artemis_rgb.Artemis "$BRANCH" || error "flatpak build-bundle failed"

echo "Flatpak build and bundle completed successfully."
