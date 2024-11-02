#!/usr/bin/env python3

import requests
from ruamel.yaml import YAML
import sys
import shutil

# Set the GraphQL endpoint
GRAPHQL_ENDPOINT = "https://updating.artemis-rgb.com/graphql"

# Define the GraphQL query
GRAPHQL_QUERY = {
    "query": """
        query {
            publishedReleases(first: 1, order: [{ createdAt: DESC }]) {
                nodes {
                    commit
                }
            }
        }
    """
}

# Send the GraphQL query
try:
    response = requests.post(GRAPHQL_ENDPOINT, json=GRAPHQL_QUERY)
    response.raise_for_status()
    data = response.json()
    ARTEMIS_COMMIT = data['data']['publishedReleases']['nodes'][0]['commit']
except (requests.RequestException, KeyError, IndexError) as e:
    print(f"Failed to retrieve Artemis commit SHA: {e}")
    sys.exit(1)

print(f"Latest Artemis commit SHA: {ARTEMIS_COMMIT}")

# Get the commit date of the Artemis commit
try:
    response = requests.get(
        f"https://api.github.com/repos/Artemis-RGB/Artemis/commits/{ARTEMIS_COMMIT}"
    )
    response.raise_for_status()
    commit_data = response.json()
    ARTEMIS_COMMIT_DATE = commit_data['commit']['committer']['date']
except (requests.RequestException, KeyError) as e:
    print(f"Failed to retrieve Artemis commit date: {e}")
    sys.exit(1)

print(f"Artemis commit date: {ARTEMIS_COMMIT_DATE}")

# Get the latest Artemis.Plugins commit that is not newer than the Artemis commit date
try:
    response = requests.get(
        "https://api.github.com/repos/Artemis-RGB/Artemis.Plugins/commits",
        params={'until': ARTEMIS_COMMIT_DATE}
    )
    response.raise_for_status()
    commits_data = response.json()
    PLUGIN_COMMIT = commits_data[0]['sha']
except (requests.RequestException, KeyError, IndexError) as e:
    print(f"Failed to retrieve Artemis.Plugins commit SHA: {e}")
    sys.exit(1)

print(f"Latest Artemis.Plugins commit SHA: {PLUGIN_COMMIT}")

# Path to the YAML manifest file
MANIFEST_FILE = "com.artemis_rgb.Artemis.yml"

# Backup the original manifest file
shutil.copyfile(MANIFEST_FILE, f"{MANIFEST_FILE}.bak")

# Load the YAML manifest file using ruamel.yaml
yaml = YAML()
yaml.preserve_quotes = True
try:
    with open(MANIFEST_FILE, 'r') as f:
        manifest = yaml.load(f)
except Exception as e:
    print(f"Failed to load manifest file '{MANIFEST_FILE}': {e}")
    sys.exit(1)

# Debug: Print loaded manifest
print(f"Type of manifest: {type(manifest)}")
print(f"Contents of manifest: {manifest}")

# Update the 'commit' field for Artemis and Artemis.Plugins in the manifest
try:
    updated = False
    for module in manifest.get('modules', []):
        if isinstance(module, dict):
            print(f"Processing module: {module.get('name')}")
            if module.get('name') == 'artemis':
                for source in module.get('sources', []):
                    print(f"Type of source: {type(source)} - Value: {source}")
                    if isinstance(source, dict):
                        if source.get('type') == 'git':
                            if source.get('url') == 'https://github.com/Artemis-RGB/Artemis.git':
                                source['commit'] = ARTEMIS_COMMIT
                                updated = True
                                print(f"Updated Artemis.git commit to {ARTEMIS_COMMIT}")
                            elif source.get('url') == 'https://github.com/Artemis-RGB/Artemis.Plugins.git':
                                source['commit'] = PLUGIN_COMMIT
                                updated = True
                                print(f"Updated Artemis.Plugins.git commit to {PLUGIN_COMMIT}")
                    else:
                        print(f"Skipping source as it is not a dict: {source}")
        else:
            print(f"Skipping module as it is not a dict: {module}")
    if not updated:
        print("No matching sources were found to update.")
except Exception as e:
    print(f"Failed to update manifest data: {e}")
    sys.exit(1)

# Write the updated manifest back to the file
try:
    with open(MANIFEST_FILE, 'w') as f:
        yaml.dump(manifest, f)
except Exception as e:
    print(f"Failed to write updated manifest file '{MANIFEST_FILE}': {e}")
    sys.exit(1)

print(f"Manifest file '{MANIFEST_FILE}' updated successfully.")
