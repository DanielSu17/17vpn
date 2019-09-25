#!/usr/bin/env python3

import json
import os
import platform
import sys
import yaml

from ruamel.yaml import YAML

print("Python Runtime Version: {0}".format(platform.python_version()))

invisible_chars = [
    u'\u2000', # En Quad
    u'\u2001', # Em Quad
    u'\u2002', # En Space
    u'\u2003', # Em Space
    u'\u2004', # Three-Per-Em Space
    u'\u2005', # Four-Per-Em Space
    u'\u2006', # Six-Per-Em Space
    u'\u2007', # Figure Space
    u'\u2008', # Punctuation Space
    u'\u2009', # Thin Space
    u'\u200a', # Hair Space
    u'\u200b', # Zero-Width Space
    u'\u200c', # Zero Width Non-Joiner
    u'\u200d', # Zero Width Joiner
    u'\u200e', # Left-To-Right Mark
    u'\u200f', # Right-To-Left Mark
    u'\u2028', # Line Separator
    u'\u2029', # Paragraph Separator
    u'\u2061', # Functional Application
    u'\u2062', # Times
    u'\u2063', # Separator
    u'\u2064', # Plus
    u'\u2800', # Braille Pattern Blank
]

check_file_count = 0
sytax_failed_count = 0
contains_invisible = 0

for dirpath, dirnames, filenames in os.walk("."):
    filenames = [f for f in filenames if f.endswith(('.yaml', '.json', '.yml'))]
    for filename in filenames:
        check_file_count += 1
        full_filename = os.path.join(dirpath, filename)
        with open(full_filename, 'r') as stream:
            try:
                # check invisible characters
                line_number = 0
                for line in stream.readlines():
                    line_number += 1
                    # remove comments if file type is YAML
                    check_line = line.split('#')[-1:] if full_filename.endswith(('.yaml', '.yml')) else line
                    for char in invisible_chars:
                        if char in check_line:
                            contains_invisible += 1
                            print('{0}: invisible character found at line {1}\n=> {2}'
                                    .format(full_filename, line_number, line))

                # reset position, or yaml/json load will fail
                stream.seek(0, 0)

                if full_filename.endswith(('.yaml', '.yml')):
                    # check yaml format
                    yamll=YAML(typ='safe')
                    yamll.load(stream)

                if full_filename.endswith('.json'):
                    # check json format
                    json.load(stream)

            except yaml.YAMLError as exc:
                sytax_failed_count += 1
                print('{0} => {1}'.format(full_filename, exc))
            except ValueError as exc:
                sytax_failed_count += 1
                print('{0} => {1}'.format(full_filename, exc))
            except Exception as e:
                print("Oops... something went wrong\nException: {0}".format(e))
            finally:
                stream.close()

print('Checked {0} files, Failed: {1}, Contains Invisible Characters: {2}'
    .format(check_file_count, sytax_failed_count, contains_invisible))

if sytax_failed_count > 0:
    sys.exit(1)

# FIXME: should return error after stable, dry-run first
# if contains_invisible > 0:
#     sys.exit(1)
