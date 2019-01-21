#!/usr/bin/env python

import io
import os
import re
import sys
import json
import time
import requests
import argparse

ENVS = ["dev", "sta", "prod"]

class I18nJsonWriter:

    # json pretty
    indent = 2
    sort_keys = True
    separators=(',', ': ')

    # file related
    path = "../envs/%s/17app/i18n/%s/%s.json"

    def __init__(self, i18n_dict):
        self.i18n_dict = i18n_dict

    def prepare_data(self, data, param_prefix):
        """
        @type data: dict
        @type param_prefix: regex
        @rtype: string
        """
        data_str = json.dumps(data, indent=self.indent, sort_keys=self.sort_keys, separators=self.separators, ensure_ascii=False).encode('utf8')

        if param_prefix is not None:
            # We need to escape '%' or client may crash
            data_str = re.sub(r'%', r'%%', data_str)
            data_str = re.sub(r'\$([0-9]+)', param_prefix, data_str)

        return data_str

    def write_file(self, full_path, data):
        """
        write file

        @type full_path: string
        @type data: string
        """
        with open(full_path, 'w') as fh:
            fh.write(data)

    def write_data(self, envs, base_name, param_prefix=None):
        """
        @type base_name: string
        @type param_prefix: regex
        """
        for env in envs:
            for lang, value in self.i18n_dict.iteritems():
                data_str = self.prepare_data(value, param_prefix)
                full_path = self.path % (env, lang.lower(), base_name)

                self.write_file(full_path, data_str)


class LokaliseClient:
    api_url = "https://api.lokalise.co/api/"

    def __init__(self, api_token):
        self.api_token = api_token

    def get_project_id_by_name(self, project_name):
        url = self.api_url + "project/list"
        payload = {"api_token": self.api_token}
        r = requests.get(url, params=payload)
        if r.status_code != 200:
            raise Exception("get languages failed")

        return [i['id'] for i in r.json()['projects'] if project_name == i['name']][0]

    def get_languages(self, project_id):
        """
        Return translated language of project id
        """
        url = self.api_url + "language/list"
        payload = {
            "api_token": self.api_token,
            "id": project_id
        }
        r = requests.get(url, params=payload)
        if r.status_code != 200:
            raise Exception("get languages failed")

        return [i['iso'] for i in r.json()['languages']]

    def get_strings(self, project_id, langs):
        """
        Get strings

        @return: {
            "en": {
                "key": "value"
            },
            "tw": {
                "key": "value"
            }
        }
        """
        ret = dict()
        url = self.api_url + "string/list"
        data = {
            "api_token": self.api_token,
            "id": project_id,
            "langs": langs
        }
        r = requests.post(url, data=data)
        if r.status_code != 200:
            raise Exception("get strings failed")
        r_json = r.json()
        if r_json['response']['code'] != '200':
            raise Exception(r_json['response']['message'])

        for lang, strings in r_json['strings'].iteritems():
            ret[lang] = dict()
            for string in strings:
                ret[lang][string['key']] = string['translation']

        return ret

    def get_all_strings(self, project_id):
        return self.get_strings(project_id, [])


if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Pull i18n from Lokalise.')
    parser.add_argument('env', choices=ENVS+["all"], default=ENVS, help='')
    args = parser.parse_args()

    if args.env == "all":
        env = ENVS
    else:
        env = [args.env]

    # get LOKALIZE_TOKEN from environment variable
    LOKALIZE_TOKEN = os.environ['LOKALIZE_TOKEN']
    if len(LOKALIZE_TOKEN.strip()) <= 0:
        print('FATAL: undefined LOKALIZE_TOKEN')
        sys.exit(1)

    lc = LokaliseClient(LOKALIZE_TOKEN)
    # Write backend.json
    p_id = lc.get_project_id_by_name("17.backend")
    iw = I18nJsonWriter(lc.get_all_strings(p_id))
    iw.write_data(env, "backend")

    # get_all_strings This method allows one request per 5 seconds
    time.sleep(5)

    # Write ios.json and android.json
    p_id = lc.get_project_id_by_name("17.backend(client)")
    iw = I18nJsonWriter(lc.get_all_strings(p_id))
    iw.write_data(env, "ios", param_prefix=r'%\1$@')
    iw.write_data(env, "android", param_prefix=r'%\1$s')
