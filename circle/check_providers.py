#!/usr/bin/env python3

import os
import platform
import sys

from ruamel.yaml import YAML

COLOR_RED = "\033[91m"
COLOR_GREEN = "\033[92m"
COLOR_YELLOW = "\033[93m"
COLOR_RESET = "\033[0m"

print("Python Runtime Version: {0}\n".format(platform.python_version()))

yaml = YAML(typ="safe")


def get_users_dict(data, key):
    rt_dict = {}
    for provider_config in data[key]:
        # skip if no 'name' defined
        if 'name' not in provider_config.keys():
            continue
        name = provider_config['name']
        # skip if no 'users' defined
        if 'users' in provider_config.keys():
            rt_dict[name] = provider_config['users']

    return rt_dict


def check_rtmp_providers(input_file):
    print("Checking RTMP Providers\nFilename: {0}".format(input_file))

    with open(input_file, 'r') as f:
        data = yaml.load(f)

    # construct dict of users
    rtmp_providers = get_users_dict(data, "rtmp_providers")

    unique_list = []
    duplicate_user_count = 0
    for name, users in rtmp_providers.items():
        for user in users:
            if user in unique_list:
                print(COLOR_YELLOW, end="")
                print("* Warning: duplicate user in [{0}: {1}]: {2}".format(
                    input_file, name, user))
                print(COLOR_RESET, end="")
                duplicate_user_count += 1
            else:
                unique_list.append(user)

    if duplicate_user_count > 0:
        print(COLOR_RED + "[FAIL]" + COLOR_RESET)
        sys.exit(1)

    print(COLOR_GREEN + "[PASS]" + COLOR_RESET)


def check_message_providers(input_file):
    print("Checking Message Providers\nFilename: {0}".format(input_file))

    with open(input_file, 'r') as f:
        data = yaml.load(f)

    # construct dict of users
    message_general = get_users_dict(data, "message_providers_general")
    message_dynamic = get_users_dict(data, "message_providers_dynamic")

    message_check_fail = 0
    if len(message_general) != len(message_dynamic):
        print("* Warning: providers length not match")
        message_check_fail += 1

    for name, users in message_general.items():
        if len(message_general[name]) != len(message_dynamic[name]):
            print(COLOR_YELLOW, end="")
            print("* Warning: users length for \"{0}\" not match".format(name))
            print(COLOR_RESET, end="")
            message_check_fail += 1

    if message_check_fail > 0:
        print(COLOR_RED + "[FAIL]" + COLOR_RESET)
        sys.exit(1)

    print(COLOR_GREEN + "[PASS]" + COLOR_RESET)


for env in ["dev", "sta", "prod"]:
    target_file = "envs/" + env + "/17app/stream/providers.yaml"
    check_rtmp_providers(target_file)
    check_message_providers(target_file)
