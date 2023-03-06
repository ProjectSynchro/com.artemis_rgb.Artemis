#!/usr/bin/env bash

set -e

# Defaults
update="all"

usage() {
   echo "usage: $(basename "$0") [-v] <verbose output> -a <update Artemis nuget sources> -p <update Artemis.Plugins nuget sources> -d <TODO: update dotnet runtime sources>"
   cat <<EOF
Basic source updater script for building the Artemis Flatpak.
This script calls on JSONMerger.py and builder-tools/dotnet/flatpak-dotnet-generator.py.
Requires python, flatpak (with correct SDKs installed for flatpak-dotnet-generator), and git.
EOF
   exit 1
}

while getopts vapd OPTION "$@"; do
    case $OPTION in
    v)
        set -x
        ;;
    a)
        update="a"
        ;;
    p)
        update="p"
        ;;
    d)
        update="d"
        ;;
    *)
        usage
        ;;
    esac
done

# Update these to follow manifest
dotnet='6'
freedesktop='22.08'
artemis_hash='66fc2988ae727cbcb1f273b3e9112cd5ca9990fc'
artemis_plugins_hash='9fbf1f9f33dac69ede804607dc278172cb9f5b1f'

# Create temporary folder.
temp=$(realpath "$(mktemp -d -p .)")

if [ "$update" = "all" ] || [ "$update" = "a" ]; then
    # Backup old source json file in case of fuck ups.
    mv artemis-sources.json artemis-sources.bak
    # Clone Git repository for Artemis, checkout the correct commit hash and run flatpak-dotnet-generator.py on Artemis.UI.Linux.csproj
    git clone https://github.com/Artemis-RGB/Artemis.git --recurse "$temp/Artemis"
    git -C "$temp/Artemis" checkout $artemis_hash
    # Generate source files for use by manifest.
    readarray -d '' projects < <(find "$temp/Artemis" -type f -name "Artemis.UI.Linux.csproj" -print0)
    ./builder-tools/dotnet/flatpak-dotnet-generator.py -d "$dotnet" -f "$freedesktop" -r linux-x64 artemis-sources.json "${projects[@]}"
fi

if [ "$update" = "all" ] || [ "$update" = "p" ]; then
    # Backup old source json file in case of fuck ups.
    mv artemis-plugins-sources.json artemis-plugins-sources.bak
    # Clone Git repository for Artemis.Plugins, checkout the correct commit hash and find all csproj files.
    git clone https://github.com/Artemis-RGB/Artemis.Plugins.git --recurse "$temp/Artemis.Plugins"
    git -C "$temp/Artemis.Plugins" checkout $artemis_plugins_hash
    # Generate source files for use by manifest.
    readarray -d '' projects < <(find "$temp/Artemis.Plugins" -type f -name "*.csproj" -print0)
    ./builder-tools/dotnet/flatpak-dotnet-generator.py -d "$dotnet" -f "$freedesktop" -r linux-x64 artemis-plugins-sources.json "${projects[@]}"
    fi

if [ "$update" = "all" ] || [ "$update" = "d" ]; then
    echo "TODO"
fi

# Cleanup our mess
rm -rf "$temp"