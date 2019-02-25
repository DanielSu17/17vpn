#!/usr/bin/env python3

import json
import os
import platform
import sys
import yaml

from ruamel.yaml import YAML

print("Python Runtime Version: {0}".format(platform.python_version()))

check_file_count = 0
sytax_failed_count = 0
for dirpath, dirnames, filenames in os.walk("."):
    filenames = [f for f in filenames if f.endswith(('.yaml', '.json', '.yml'))]
    for filename in filenames:
        check_file_count += 1
        full_filename = os.path.join(dirpath, filename)
        with open(full_filename, 'r') as stream:
            try:
                if (full_filename.endswith('.yaml') or
                    full_filename.endswith('.yml')):
                    yamll=YAML(typ='safe')
                    yamll.load(stream)
                if full_filename.endswith('.json'):
                    json.load(stream)
            except yaml.YAMLError as exc:
                sytax_failed_count += 1
                print('{0} => {1}'.format(full_filename, exc))
            except ValueError as exc:
                sytax_failed_count += 1
                print('{0} => {1}'.format(full_filename, exc))
            finally:
                stream.close()

print('Checked {0} files, Failed: {1}'.format(
    check_file_count, sytax_failed_count))

if sytax_failed_count > 0:
    sys.exit(1)
