#!/usr/bin/env python3

# Quick and dirty JSON merger.

import json
import sys

files=sys.argv
del files[0]

def merge_JsonFiles(filename):
    result = list()
    for f1 in filename:
        with open(f1, 'r') as infile:
            result.extend(json.load(infile))

    with open('plugin-sources.json', 'w') as output_file:
        json.dump(result, output_file)

merge_JsonFiles(files)