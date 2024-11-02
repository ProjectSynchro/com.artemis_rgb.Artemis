#!/usr/bin/env bash

set -e

# Extract variables from the manifest
manifest="com.artemis_rgb.Artemis.yml"

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq is not installed. Please install it to proceed."
    exit 1
fi

# Extract the dotnet version
dotnet=$(yq '.sdk-extensions[] | select(. == "*dotnet*") | sub(".*dotnet", "")' "$manifest")

# Extract the freedesktop runtime version
freedesktop=$(yq '.runtime-version' "$manifest" | tr -d "'")

# Extract the artemis hash
artemis_hash=$(yq '.modules[] | select(.name == "artemis") | .sources[] | select(.url == "https://github.com/Artemis-RGB/Artemis.git") | .commit' "$manifest")

# Extract the artemis plugins hash
artemis_plugins_hash=$(yq '.modules[] | select(.name == "artemis") | .sources[] | select(.url == "https://github.com/Artemis-RGB/Artemis.Plugins.git") | .commit' "$manifest")

# Create temporary folder.
temp=$(realpath "$(mktemp -d -p .)")

# Backup old source json file in case of issues.
mv artemis-sources.json artemis-sources.bak

# Clone Git repository for Artemis, checkout the correct commit hash and run flatpak-dotnet-generator.py on Artemis.UI.Linux.csproj
git clone https://github.com/Artemis-RGB/Artemis.git --recurse "$temp/Artemis"
git -C "$temp/Artemis" checkout "$artemis_hash"

# Generate source files for use by manifest.
readarray -d '' projects < <(find "$temp/Artemis" -type f -name "Artemis.UI.Linux.csproj" -print0)
./builder-tools/dotnet/flatpak-dotnet-generator.py -d "$dotnet" -f "$freedesktop" -r linux-x64 artemis-sources.json "${projects[@]}"

# Backup old source json file in case of issues.
mv artemis-plugins-sources.json artemis-plugins-sources.bak

# Clone Git repository for Artemis.Plugins, checkout the correct commit hash and find all csproj files.
git clone https://github.com/Artemis-RGB/Artemis.Plugins.git --recurse "$temp/Artemis.Plugins"
git -C "$temp/Artemis.Plugins" checkout "$artemis_plugins_hash"

# Generate source files for use by manifest.
readarray -d '' projects < <(find "$temp/Artemis.Plugins" -type f -name "*.csproj" -print0)
./builder-tools/dotnet/flatpak-dotnet-generator.py -d "$dotnet" -f "$freedesktop" -r linux-x64 artemis-plugins-sources.json "${projects[@]}"

# Cleanup our mess
rm -rf "$temp"
