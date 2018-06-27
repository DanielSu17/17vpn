#!/usr/bin/env python

import os
import yaml
import json
from ruamel.yaml import YAML
import sys

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
                print '%s => %s' % (full_filename, exc)
                sytax_failed_count += 1
            except ValueError as exc:
                print '%s => %s' % (full_filename, exc)
                sytax_failed_count += 1
            finally:
                stream.close()
print 'Need Syntax Check Files Count: %s, Failed Files Count: %s' % (check_file_count, sytax_failed_count)

if sytax_failed_count > 0:
    sys.exit(1)
