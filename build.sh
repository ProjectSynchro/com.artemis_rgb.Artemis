#!/usr/bin/env bash

set -e

# Defaults
VersionNumber=""

usage() {
   echo "usage: $(basename "$0") [-v] <verbose output> -h <this help dialog>"
   cat <<EOF
Basic build script for use by flatpak-builder when building the Artemis Flatpak.
Should just require 'git', 'grep' and gnu coreutils.
EOF
   exit 1
}

while getopts vh OPTION "$@"; do
    case $OPTION in
    v)
        set -x
        ;;
    h)
        usage
        ;;
    *)
        usage
        ;;
    esac
done

function GetVersion {
    # Attempt to recreate 'version' job step from gh-actions branch workflow:
    # https://github.com/Artemis-RGB/Artemis/blob/feature/gh-actions/.github/workflows/master.yml
    local CoreProjFile
    local ApiVersion
    #local BranchName
    local BuildDate
    local NumberOfCommitsToday

        # Find Artemis.Core csproj
        CoreProjFile=$(find "Artemis/src" -type f -name "Artemis.Core.csproj")

        # Sed-fu the backslashes and periods in branch names. (Unused)
        #BranchName=$(git symbolic-ref --short -q HEAD | sed -r 's/[/.]+/-/g')

        # Don't even want to attempt to parse xml with grep/awk/sed.. lol
        ApiVersion=$(grep -o -P '(?<=<PluginApiVersion>).*(?=</PluginApiVersion>)' "$CoreProjFile")

        # Get the number of commits using git rev-list, should be legit afaik
        pushd Artemis
        BuildDate=$(date --utc +"%Y-%m-%d")
        NumberOfCommitsToday=$(git rev-list --count --after="$BuildDate 00:00" --before="$BuildDate 00:00" HEAD)
        popd
        # Assemble Final Version Number
        VersionNumber="$ApiVersion.$(date +"%Y.%m%d").$NumberOfCommitsToday"
}

# Set variables for output and build directories to be used later
PluginOutDir="build/build-plugins"
StagingDir="build/$RUNTIME"
PluginStagingDir="$StagingDir/Plugins"

# Create build output and staging directories.
mkdir -p "$PluginOutDir" "$StagingDir" "$PluginStagingDir"

# Build Artemis UI component
echo "Building Artemis.UI.Linux"
GetVersion
UIProjFile=$(find "Artemis/src" -type f -name "Artemis.UI.Linux.csproj")
dotnet publish --configuration Release -p:Version="$VersionNumber" --runtime "$RUNTIME" --source ./nuget-sources --output "$StagingDir" --self-contained "$UIProjFile"

# Build default Artemis plugins
echo "Building Artemis.Plugins"

# Search for all plugin projects
PluginProjects=$(find "Artemis.Plugins/src" -type f -name "*.csproj")

for PluginProjFile in $PluginProjects; do
    # Build each of the found project files.
    Name=$(basename -s .csproj "$PluginProjFile")
    echo "Building Plugin $Name"
    Output="$PluginOutDir/$Name"
    dotnet publish --configuration Release --runtime "$RUNTIME" --source ./nuget-sources --output "$Output" --no-self-contained "$PluginProjFile";
    # Zip the output and place it inside of the staging directory for app deployment
    pushd "$Output"
        zip -r "$Name.zip" .
    popd
    mv "$PluginOutDir/$Name/$Name.zip" "$PluginStagingDir"
done

echo "Staging Artemis Flatpak"

# Install Metainfo and desktop files
install -Dm644 com.artemis_rgb.Artemis.metainfo.xml /app/share/metainfo/com.artemis_rgb.Artemis.metainfo.xml
install -Dm644 com.artemis_rgb.Artemis.desktop /app/share/applications/com.artemis_rgb.Artemis.metainfo.desktop

# Install
pushd icons
find . -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' folder
do
    install -Dm644 "$folder/com.artemis_rgb.Artemis.png" "/app/share/icons/hicolor/$folder/apps/com.artemis_rgb.Artemis.png"
done
popd 

# Set executable bit on Artemis binary
chmod +x "$StagingDir/Artemis.UI.Linux"
# Install files to Flatpak staging folder.
cp -r --remove-destination "$StagingDir" /app/bin/

