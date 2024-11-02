#!/usr/bin/env bash

# Set the GraphQL endpoint (replace with your actual endpoint)
GRAPHQL_ENDPOINT="https://updating.artemis-rgb.com/graphql"

# Define the GraphQL query to get the latest published release commit SHA
GRAPHQL_QUERY='{"query": "query { publishedReleases(first: 1, order: [{ createdAt: DESC }]) { nodes { commit } } }"}'

# Get the latest Artemis commit SHA
ARTEMIS_COMMIT=$(curl -s -X POST -H "Content-Type: application/json" -d "$GRAPHQL_QUERY" "$GRAPHQL_ENDPOINT" | \
  jq -r '.data.publishedReleases.nodes[0].commit')

# Check if the commit was retrieved
if [ -z "$ARTEMIS_COMMIT" ] || [ "$ARTEMIS_COMMIT" == "null" ]; then
  echo "Failed to retrieve Artemis commit SHA."
  exit 1
fi

echo "Latest Artemis commit SHA: $ARTEMIS_COMMIT"

# Get the commit date of the Artemis commit
ARTEMIS_COMMIT_DATE=$(curl -s "https://api.github.com/repos/Artemis-RGB/Artemis/commits/$ARTEMIS_COMMIT" | \
  jq -r '.commit.committer.date')

# Check if the date was retrieved
if [ -z "$ARTEMIS_COMMIT_DATE" ] || [ "$ARTEMIS_COMMIT_DATE" == "null" ]; then
  echo "Failed to retrieve Artemis commit date."
  exit 1
fi

echo "Artemis commit date: $ARTEMIS_COMMIT_DATE"

# Get the latest Artemis.Plugins commit that is not newer than the Artemis commit date
PLUGIN_COMMIT=$(curl -s "https://api.github.com/repos/Artemis-RGB/Artemis.Plugins/commits?until=$ARTEMIS_COMMIT_DATE" | \
  jq -r '.[0].sha')

# Check if the plugin commit was retrieved
if [ -z "$PLUGIN_COMMIT" ] || [ "$PLUGIN_COMMIT" == "null" ]; then
  echo "Failed to retrieve Artemis.Plugins commit SHA."
  exit 1
fi

echo "Latest Artemis.Plugins commit SHA: $PLUGIN_COMMIT"

# Path to the YAML manifest file
MANIFEST_FILE="com.artemis_rgb.Artemis.yml"

# Backup the original manifest file
cp "$MANIFEST_FILE" "${MANIFEST_FILE}.bak"

# Update the 'commit' field for Artemis and Artemis.Plugins in the manifest using yq
yq eval -i '
  (.modules[] | select(.name == "artemis") | .sources[] | select(.type == "git" and .url == "https://github.com/Artemis-RGB/Artemis.git") | .commit) = "'$ARTEMIS_COMMIT'" |
  (.modules[] | select(.name == "artemis") | .sources[] | select(.type == "git" and .url == "https://github.com/Artemis-RGB/Artemis.Plugins.git") | .commit) = "'$PLUGIN_COMMIT'"
' "$MANIFEST_FILE"

echo "Manifest file '$MANIFEST_FILE' updated successfully."
