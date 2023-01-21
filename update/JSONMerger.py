#!/usr/bin/env python3

# Quick and dirty JSON merger.
# Does not check for duplicates, which is not the most efficient when reading and downloading with flatpak-builder.
# I'm no python or JSON user by any stretch so feel free to submit improvements! :)

import os.path, sys, json

# Set output file and files list vars up
out = ''
files = []

# Repeatable usage function
def usage():
    print("Usage: %s (--help) outputfile.json input-file1.json input-file2.json input-file3.json etc..." % os.path.basename(__file__))

# Simple script to set output file and check if inputs exist, could add more error checking but this is just called by a bash script anyways..
def get_Arguments(argv):
    n = len(argv)

    if n <= 3 or argv[1] == "--help":
        print("You need to have at least 2 files to merge them!", file=sys.stderr)
        usage()
        exit
    else:
        out = str(argv[1])
        for i in range(2, n):
            files.append(str(argv[i]))

# Merge two or more JSON files by adding their dictionaries to a list and dumping said list to a file
# Tried looking into checking for duplicate entries but my head hurts. Need to learn more python3.

def merge_JsonFiles(filename):
    result = list()

    for f1 in filename:
        with open(f1, 'r') as infile:
            result.extend(json.load(infile))

    with open(out, 'w') as output_file:
        json.dump(result, output_file)

get_Arguments(sys.argv)
merge_JsonFiles(files)
