#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess
import shutil
import logging
import tempfile
from ruamel.yaml import YAML

# ---------------------------
# Configuration
# ---------------------------

# Paths and files
MANIFEST_FILE = "com.artemis_rgb.Artemis.yml"  # Path to your Flatpak manifest YAML file

# ---------------------------
# Functions
# ---------------------------

def error(message):
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)

def check_command(cmd):
    if shutil.which(cmd) is None:
        error(f"'{cmd}' is not installed. Please install it and try again.")

# ---------------------------
# Parse Command Line Arguments
# ---------------------------

parser = argparse.ArgumentParser(description='Update Artemis and Artemis.Plugins sources.')
parser.add_argument('-v', action='store_true', help='Verbose output')
parser.add_argument('-a', action='store_true', help='Update Artemis NuGet sources')
parser.add_argument('-p', action='store_true', help='Update Artemis.Plugins NuGet sources')

args = parser.parse_args()

if args.v:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.INFO)

if args.a and args.p:
    UPDATE_TARGET = "all"
elif args.a:
    UPDATE_TARGET = "a"
elif args.p:
    UPDATE_TARGET = "p"
else:
    UPDATE_TARGET = "all"

# ---------------------------
# Check for Required Tools
# ---------------------------

logging.info("Checking for required tools...")

REQUIRED_TOOLS = [
    "git",
    "python",
    "yq",
]

for cmd in REQUIRED_TOOLS:
    check_command(cmd)

logging.info("All required tools are installed.")

# ---------------------------
# Extract Variables from Manifest
# ---------------------------

logging.info("Extracting variables from manifest...")

if not os.path.isfile(MANIFEST_FILE):
    error(f"Manifest file '{MANIFEST_FILE}' not found.")

yaml = YAML(typ='safe')  # Use 'safe' load to prevent arbitrary code execution

with open(MANIFEST_FILE, 'r') as f:
    manifest = yaml.load(f)

# Extract the .NET version
DOTNET_VERSION = None
sdk_extensions = manifest.get('sdk-extensions', [])
for ext in sdk_extensions:
    if 'dotnet' in ext:
        DOTNET_VERSION = ext.split('dotnet')[-1]
        break

if not DOTNET_VERSION:
    error("Failed to extract .NET version from manifest.")
logging.info(f".NET version: {DOTNET_VERSION}")

# Extract the Freedesktop runtime version
FREEDESKTOP_VERSION = manifest.get('runtime-version', '').replace("'", '')
if not FREEDESKTOP_VERSION:
    error("Failed to extract Freedesktop runtime version from manifest.")
logging.info(f"Freedesktop runtime version: {FREEDESKTOP_VERSION}")

# Extract commit hashes
modules = manifest.get('modules', [])
ARTEMIS_HASH = None
ARTEMIS_PLUGINS_HASH = None

for module in modules:
    logging.debug(f"Processing module: {module}")
    if isinstance(module, dict):
        if module.get('name') == 'artemis':
            sources = module.get('sources', [])
            for source in sources:
                if isinstance(source, dict):
                    url = source.get('url')
                    if url == 'https://github.com/Artemis-RGB/Artemis.git':
                        ARTEMIS_HASH = source.get('commit')
                    elif url == 'https://github.com/Artemis-RGB/Artemis.Plugins.git':
                        ARTEMIS_PLUGINS_HASH = source.get('commit')
                else:
                    logging.debug(f"Skipping source (not a dict): {source}")
        else:
            logging.debug(f"Module name is not 'artemis': {module.get('name')}")
    else:
        logging.debug(f"Skipping module (not a dict): {module}")
        continue


if not ARTEMIS_HASH:
    error("Failed to extract Artemis commit hash from manifest.")
logging.info(f"Artemis commit hash: {ARTEMIS_HASH}")

if not ARTEMIS_PLUGINS_HASH:
    error("Failed to extract Artemis.Plugins commit hash from manifest.")
logging.info(f"Artemis.Plugins commit hash: {ARTEMIS_PLUGINS_HASH}")

# ---------------------------
# Create Temporary Directory
# ---------------------------

logging.info("Creating temporary directory...")
TEMP_DIR = tempfile.mkdtemp(dir='.')
if not os.path.isdir(TEMP_DIR):
    error("Failed to create temporary directory.")
logging.info(f"Temporary directory created at '{TEMP_DIR}'.")

# ---------------------------
# Update Sources Functions
# ---------------------------

def update_artemis_sources():
    logging.info("Updating Artemis sources...")

    if os.path.isfile('artemis-sources.json'):
        shutil.move('artemis-sources.json', 'artemis-sources.bak')
        logging.info("Backed up existing 'artemis-sources.json' to 'artemis-sources.bak'.")

    artemis_repo_dir = os.path.join(TEMP_DIR, 'Artemis')
    cmd = ['git', 'clone', '--recurse', 'https://github.com/Artemis-RGB/Artemis.git', artemis_repo_dir]
    result = subprocess.run(cmd)
    if result.returncode != 0:
        error("Failed to clone Artemis repository.")

    cmd = ['git', '-C', artemis_repo_dir, 'checkout', ARTEMIS_HASH]
    result = subprocess.run(cmd)
    if result.returncode != 0:
        error(f"Failed to checkout commit '{ARTEMIS_HASH}'.")

    projects = []
    for root, dirs, files in os.walk(artemis_repo_dir):
        for file in files:
            if file == 'Artemis.UI.Linux.csproj':
                projects.append(os.path.join(root, file))
    if len(projects) == 0:
        error("No 'Artemis.UI.Linux.csproj' file found.")

    logging.info("Generating 'artemis-sources.json'...")
    cmd = ['./builder-tools/dotnet/flatpak-dotnet-generator.py',
           '-r', 'linux-x64', 'linux-arm64',
           '-d', DOTNET_VERSION,
           '-f', FREEDESKTOP_VERSION,
           'artemis-sources.json'] + projects

    result = subprocess.run(cmd)
    if result.returncode != 0:
        error("Failed to generate 'artemis-sources.json'.")

    logging.info("'artemis-sources.json' generated successfully.")

def update_artemis_plugins_sources():
    logging.info("Updating Artemis.Plugins sources...")

    if os.path.isfile('artemis-plugins-sources.json'):
        shutil.move('artemis-plugins-sources.json', 'artemis-plugins-sources.bak')
        logging.info("Backed up existing 'artemis-plugins-sources.json' to 'artemis-plugins-sources.bak'.")

    artemis_plugins_repo_dir = os.path.join(TEMP_DIR, 'Artemis.Plugins')
    cmd = ['git', 'clone', '--recurse', 'https://github.com/Artemis-RGB/Artemis.Plugins.git', artemis_plugins_repo_dir]
    result = subprocess.run(cmd)
    if result.returncode != 0:
        error("Failed to clone Artemis.Plugins repository.")

    cmd = ['git', '-C', artemis_plugins_repo_dir, 'checkout', ARTEMIS_PLUGINS_HASH]
    result = subprocess.run(cmd)
    if result.returncode != 0:
        error(f"Failed to checkout commit '{ARTEMIS_PLUGINS_HASH}'.")

    projects = []
    for root, dirs, files in os.walk(artemis_plugins_repo_dir):
        for file in files:
            if file.endswith('.csproj'):
                projects.append(os.path.join(root, file))
    if len(projects) == 0:
        error("No '.csproj' files found in Artemis.Plugins.")

    logging.info("Generating 'artemis-plugins-sources.json'...")
    cmd = ['./builder-tools/dotnet/flatpak-dotnet-generator.py',
           '-r', 'linux-x64', 'linux-arm64',
           '-d', DOTNET_VERSION,
           '-f', FREEDESKTOP_VERSION,
           'artemis-plugins-sources.json'] + projects

    result = subprocess.run(cmd)
    if result.returncode != 0:
        error("Failed to generate 'artemis-plugins-sources.json'.")

    logging.info("'artemis-plugins-sources.json' generated successfully.")

# ---------------------------
# Update Sources Based on Selection
# ---------------------------

if UPDATE_TARGET == 'all':
    update_artemis_sources()
    update_artemis_plugins_sources()
elif UPDATE_TARGET == 'a':
    update_artemis_sources()
elif UPDATE_TARGET == 'p':
    update_artemis_plugins_sources()
else:
    parser.print_help()
    sys.exit(1)

# ---------------------------
# Clean Up
# ---------------------------

logging.info("Cleaning up temporary files...")
shutil.rmtree(TEMP_DIR)
logging.info(f"Temporary directory '{TEMP_DIR}' removed.")
logging.info("Temporary files cleaned up.")

# ---------------------------
# Completion Message
# ---------------------------

logging.info("Source update completed successfully.")
