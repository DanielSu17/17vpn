#!/usr/bin/env python3

import json
import os
import platform
import sys

print("Python Runtime Version: {0}".format(platform.python_version()))

target_file = "envs/prod/17app/stream/supporttypes.json"

with open(target_file, 'r') as f:
    data = json.load(f)

# construct dict of users
users_dict = {}
for provider_config in data['rtmp_cdn']:
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
            print("Warning: duplicate user in {} list: {}".format(name, user))
            duplicate_user_count += 1
        else:
            unique_list.append(user)

if duplicate_user_count > 0:
    sys.exit(1)
