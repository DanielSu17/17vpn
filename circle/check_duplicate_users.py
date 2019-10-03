#!/usr/bin/env python3

import os
import platform
import sys

from ruamel.yaml import YAML

yaml=YAML(typ="safe")

print("Python Runtime Version: {0}".format(platform.python_version()))

def check_duplicate(input_file):
    print("Checking: {0}".format(input_file))

    with open(input_file, 'r') as f:
        data = yaml.load(f)

    # construct dict of users
    users_dict = {}
    for provider_config in data['rtmp_providers']:
        # skip if no 'name' defined
        if 'name' not in provider_config.keys():
            continue
        name = provider_config['name']
        # skip if no 'users' defined
        if 'users' in provider_config.keys():
            users_dict[name] = provider_config['users']

    unique_list = []
    duplicate_user_count = 0
    for name, users in users_dict.items():
        for user in users:
            if user in unique_list:
                print("* Warning: duplicate user in [{0}: {1}]: {2}".format(input_file, name, user))
                duplicate_user_count += 1
            else:
                unique_list.append(user)

    if duplicate_user_count > 0:
        print("[FAIL]")
        sys.exit(1)

    print("[PASS]")

for env in ["dev", "sta", "prod"]:
    target_file = "envs/" + env + "/17app/stream/providers.yaml"
    check_duplicate(target_file)
