#!/usr/bin/env python

from __future__ import print_function
from ruamel.yaml import YAML

import json
import os
import sys
import yaml


check_file_count = 0
sytax_failed_count = 0

for dirpath, dirnames, filenames in os.walk("."):
    for filename in [f for f in filenames if f.endswith(('.yaml', '.json', 'yml'))]:
        check_file_count += 1
        full_filename = os.path.join(dirpath, filename)
        with open(full_filename, 'r') as stream:
            try:
                if full_filename.endswith('.yaml') or full_filename.endswith('yml'):
                    # YAML(typ='safe') accomplishes the same as what yaml.safe_load() did
                    yamll=YAML(typ='safe')
                    yamll.load(stream)
                if full_filename.endswith('.json'):
                    json.load(stream)
            except yaml.YAMLError as exc:
                print('{0} => {1}'.format(full_filename, exc))
                sytax_failed_count += 1
            except ValueError as exc:
                print('{0} => {1}'.format(full_filename, exc))
                sytax_failed_count += 1
            finally:
                stream.close()

print('Total File Count: {0}'.format(check_file_count))
print('Syntax Check Failed Count: {0}'.format(sytax_failed_count))

if sytax_failed_count > 0:
    sys.exit(1)
