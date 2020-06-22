#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import requests
import json

access_token = 'BAf9qBQPVG.yA<b(q2xBF5gLhc5cGp5QF3JMu0'
api = { 'prod': 'https://api-dsa.17app.co' }
result, warning = 0, 0

def highlight(text, status):
    attrs = []
    colors = {
        'green': '32',
        'red': '31',
        'yellow': '33',
        'dark_gray': '90',
        'light_gray': '39'
    }
    if not sys.stdout.isatty():
        return text
    attrs.append(colors.get(status, 'red'))
    attrs.append('1')
    return '\x1b[%sm%s\x1b[0m' % (';'.join(attrs), text)

def remote_check_configs(env, files_list):
    headers = {'accesstoken': access_token, "origin": "config.remote.check"}
    metadata = {}
    files = {}
    for idx, file in enumerate(files_list):
        key = "file%s" % str(idx + 1)
        files[key] = open("envs/%s/%s" % (env, file))
        metadata[key] = {"path": file}

    rp_metadata = {"metadata": json.dumps(metadata)}
    response = requests.request("POST",
                                "%s/api/v1/config/check" % api[env],
                                headers=headers,
                                data=rp_metadata,
                                files=files)
    jsonObject = json.loads(response.text)
    print(display_response(env, jsonObject))
    set_result(jsonObject)

def set_result(messages):
    global warning
    global result
    if 'error' in messages and len(messages['error']) > 0:
        result = 1
    if 'warning' in messages and len(messages['warning']) > 0:
        warning = 1

def display_response(env, response):
    s = ""
    for status in response:
        for filepath in response[status]:
            s += highlight("  [{}]\n".format(status.upper()),
                           status_color(status))
            s += "    <envs/{}/{}>:\n".format(env, filepath)
            s += pretty_message(filepath, response[status][filepath])
    return s

def status_color(status):
    if status == 'error':
        return 'red'
    else:
        return 'yellow'


def pretty_message(status, messages):
    s = ""
    for idx, text in enumerate(messages):
        first_line = 1
        for line in text.splitlines():
            str_chr = "  "
            if first_line == 1:
                str_chr, first_line = "- ", 0
            s += highlight("      {}{}\n".format(str_chr,
                                                 str(line.encode('utf-8'))),
                                                 line_color(idx))
    return s

def line_color(idx):
    if idx % 2 == 0:
        return 'light_gray'
    else:
        return 'dark_gray'

def main():
    configs = [
        "17app/live/user-msg-brd-metal.yaml",
        "17app/live/user-msg-brd-gradient.yaml",
        "17app/live/user-msg-brd-candy-cane.yaml",
    ]
    remote_check_configs("prod", configs)
    sys.exit(result)

if __name__ == '__main__':
    main()
