#!/usr/bin/env python3

import json
import os
import platform
import sys
import yaml

from ruamel.yaml import YAML

print("Python Runtime Version: {0}".format(platform.python_version()))

invalid_chars = [
    u'\u200a', # Hair Space
    u'\u200b', # Zero-Width Space
    u'\u200c', # Zero Width Non-Joiner
    u'\u200d', # Zero Width Joiner
    u'\u200e', # Left-To-Right Mark
    u'\u200f', # Right-To-Left Mark
]

check_file_count = 0
sytax_failed_count = 0

for dirpath, dirnames, filenames in os.walk("."):
    filenames = [f for f in filenames if f.endswith(('.yaml', '.json', '.yml'))]
    for filename in filenames:
        check_file_count += 1
        full_filename = os.path.join(dirpath, filename)
        with open(full_filename, 'r') as stream:
            try:
                # FIXME: it should check json as well
                # but `stream` will be changed after yaml.load(), json.load()
                # so ignore it, or it will emit too much error messages
                if full_filename.endswith(('.yaml', '.yml')):
                    # check invisible characters
                    line_number = 0
                    for line in stream.readlines():
                        line_number += 1
                        check_line = line.split('#')[-1:]
                        for char in invalid_chars:
                            if char in check_line:
                                print('{0}: invisible character found at line {1}\n=> {2}'
                                        .format(full_filename, line_number, line))
                                # TODO: should return error after stable
                                # sys.exit(1)

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
            except:
                print("Oops... something went wrong")
            finally:
                stream.close()

print('Checked {0} files, Failed: {1}'.format(
    check_file_count, sytax_failed_count))

if sytax_failed_count > 0:
    sys.exit(1)
