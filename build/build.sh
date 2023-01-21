#!/usr/bin/env bash

VersionNumber=''

function getVersion {
# Attempt to recreate 'version' job step from gh-actions branch workflow:
# https://github.com/Artemis-RGB/Artemis/blob/feature/gh-actions/.github/workflows/master.yml
# Should just require 'git', 'grep' and gnu coreutils.

local ApiVersion
#local BranchName
local BuildDate
local NumberOfCommitsToday

    # Sed-fu the backslashes and periods in branch names. (Unused)
    #BranchName=$(git symbolic-ref --short -q HEAD | sed -r 's/[/.]+/-/g')

    # Don't even want to attempt to parse xml with grep/awk/sed.. lol
    ApiVersion=$(grep -o -P '(?<=<PluginApiVersion>).*(?=</PluginApiVersion>)' ./src/Artemis.Core/Artemis.Core.csproj)

    # Get the number of commits using git rev-list, should be legit afaik
    BuildDate=$(date --utc +"%Y-%m-%d")
    NumberOfCommitsToday=$(git rev-list --count --after="$BuildDate 00:00" --before="$BuildDate 00:00" HEAD)

    # Assemble Final Version Number
    VersionNumber="$ApiVersion.$(date +"%Y.%m%d").$NumberOfCommitsToday"
}

getVersion

echo "BUILDING ARTEMIS"
dotnet publish --configuration Release -p:Version="$VersionNumber" --runtime "$RUNTIME" --source ./nuget-sources --output build/"$RUNTIME" --self-contained src/Artemis.UI.Linux/Artemis.UI.Linux.csproj
cp -r --remove-destination /run/build/artemis/build/linux-x64/ /app/bin/
chmod +x /app/bin/Artemis.UI.Linux
