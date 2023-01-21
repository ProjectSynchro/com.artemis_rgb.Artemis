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

# Create temporary folder and nuke old one just in case.
rm -rf update-temp || exit 0
mkdir -p update-temp

if [ "$update" = "b" ] || [ "$update" = "a" ]; then
    # Backup old source json file in case of fuck ups.
    mv ../artemis-sources.json ../artemis-sources.bak
    # Clone Git folder for Artemis and run flatpak-dotnet-generator.py on Artemis.UI.Linux.csproj
    git clone https://github.com/Artemis-RGB/Artemis.git --recurse update-temp/Artemis
    project=$(find "update-temp/Artemis/src" -type f -name "Artemis.UI.Linux.csproj")
    ./builder-tools/dotnet/flatpak-dotnet-generator.py --runtime linux-arm64 ./update-temp/linux-arm64-sources.json "$project"
    ./builder-tools/dotnet/flatpak-dotnet-generator.py --runtime linux-x64 ./update-temp/linux-x64-sources.json "$project"

    # Merge both x86_64 and aarch64 dependencies into artemis-sources.json
    ./JSONMerger.py ../artemis-sources.json ./update-temp/linux-x64-sources.json ./update-temp/linux-arm64-sources.json
fi

if [ "$update" = "b" ] || [ "$update" = "p" ]; then
    # Backup old source json file in case of fuck ups.
    mv ../artemis-plugins-sources.json ../artemis-plugins-sources.bak
    # Clone Git folder for Artemis.Plugins and find all csproj files.
    git clone https://github.com/Artemis-RGB/Artemis.Plugins.git --recurse ./update-temp/Artemis.Plugins
    plugin_projects=$(find "update-temp/Artemis.Plugins/src" -type f -name "*.csproj")

    new=1
    for project in $plugin_projects; do
        # Run flatpak-dotnet-generator.py on all Plugin Prijects to get all dependencies.
        name=$(basename -s .csproj "$project")
        ./builder-tools/dotnet/flatpak-dotnet-generator.py --runtime linux-arm64 "./update-temp/linux-arm64-$name-sources.json" "$project"
        ./builder-tools/dotnet/flatpak-dotnet-generator.py --runtime linux-x64 "./update-temp/linux-x64-$name-sources.json" "$project"

        # Merge all plugin dependencies into a single file for ease of maintenance for the build manifest
        if [ "$new" -eq 1 ]; then
            ./JSONMerger.py "../artemis-plugins-sources.json" "./update-temp/linux-arm64-$name-sources.json" "./update-temp/linux-x64-$name-sources.json"
        else
            ./JSONMerger.py "../artemis-plugins-sources.json" "../artemis-plugins-sources.json" "./update-temp/linux-arm64-$name-sources.json" "./update-temp/linux-x64-$name-sources.json"
        fi
        new=0
    done
fi

if [ "$update" = "all" ] || [ "$update" = "d" ]; then
    echo "TODO"
fi

# Cleanup our mess
rm -rf update-temp