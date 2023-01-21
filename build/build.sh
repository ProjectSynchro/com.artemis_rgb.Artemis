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
    GetVersion

    OutDir="build/build-plugins"
    StagingDir="build/$RUNTIME"
    PluginStagingDir="$StagingDir/Plugins"

    mkdir -p "$OutDir" "$StagingDir" "$PluginStagingDir"

    echo "Building Artemis.UI.Linux"
    UIProjFile=$(find "Artemis/src" -type f -name "Artemis.UI.Linux.csproj")
    dotnet publish --configuration Release -p:Version="$VersionNumber" --runtime "$RUNTIME" --source ./nuget-sources --output "$StagingDir" --self-contained "$UIProjFile"

    echo "Building Artemis.Plugins"
    
    PluginProjects=$(find "Artemis.Plugins/src" -type f -name "*.csproj")
    for PluginProjFile in $PluginProjects; do
        Name=$(basename -s .csproj "$PluginProjFile")
        echo "Building Plugin $Name"
        Output="$OutDir/$Name"

        dotnet publish --configuration Release --runtime "$RUNTIME" --source ./nuget-sources --output "$Output" --no-self-contained "$PluginProjFile";

        pushd "$Output"
        zip -r "$Name.zip" .
        popd
        mv "$OutDir/$Name/$Name.zip" "$PluginStagingDir"
    done
    echo "Staging Artemis Flatpak"
    chmod +x "$StagingDir/Artemis.UI.Linux"
    cp -r --remove-destination "$StagingDir" /app/bin/
