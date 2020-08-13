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

backend_internal_mapping = {
    "zh_TW": "zh-hant",
    "zh_CN": "zh-hans",
    "en":    "en",
    "zh_SG": "zh-sg",
}

class I18nJsonWriter:

    # json pretty
    indent = 2
    sort_keys = True
    separators=(',', ': ')

    # file related
    path = "../../envs/%s/%s/i18n/%s/%s.json"

    def __init__(self, i18n_dict, project):
        self.i18n_dict = i18n_dict
        self.project = project

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
                full_path = self.path % (env, self.project, lang.lower(), base_name)

                self.write_file(full_path, data_str)

class LokaliseClient:
    api_url = "https://api.lokalise.co/api2/"

    def __init__(self, api_token):
        self.api_token = api_token

    def get_project_id_by_name(self, project_name):
        url = self.api_url + "projects"
        headers = {
            'x-api-token': self.api_token
        }
        r = requests.get(url, headers=headers)
        if r.status_code != 200:
            raise Exception("get languages failed")
        for i in r.json()['projects']:
            if project_name == i['name']:
                return i['project_id']
        return ""

    def get_languages(self, project_id):
        """
        Return translated language of project id
        """
        url = self.api_url + "projects/" + project_id + "/languages"
        headers = {
            'x-api-token': self.api_token
        }
        r = requests.get(url, headers=headers)
        if r.status_code != 200:
            raise Exception("get languages failed")

        return [i['iso'] for i in r.json()['languages']]

    def get_translations(self, project_id):
        """
        Return translations of project id
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
        # get languages
        url = self.api_url + "projects/" + project_id + "/languages"
        headers = {
            'x-api-token': self.api_token
        }
        r = requests.get(url, headers=headers)
        if r.status_code != 200:

            raise Exception("get languages failed")
        for lang in r.json()['languages']:
            ret[lang['lang_iso']] = dict()

        # get translations from keys api
        url = self.api_url + "projects/" + project_id + "/keys"
        headers = {
            'x-api-token': self.api_token
        }
        count = 0
        page = 1
        # page > 100 means 500000 keys, should never happend just set for safe
        while page < 100:
            payload = {
                'include_translations':'1',
                'page': page,
                'limit': 5000
            }
            r = requests.get(url, headers=headers, params=payload)
            if r.status_code != 200:
                raise Exception("get translations failed")

            keys = r.json()['keys']
            for key in keys:
                for translation in key['translations']:
                    ret[translation['language_iso']][key['key_name']['other']] = translation['translation']
            count += len(keys)
            if count >= int(r.headers['X-Pagination-Total-Count']) or len(r.json()['keys']) == 0:
                break
            page+=1
        return ret

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

    p_id = lc.get_project_id_by_name("Wave")
    backend_client_keys = lc.get_translations(p_id)

    for k, v in backend_internal_mapping.iteritems():
      try:
        backend_client_keys[v] = backend_client_keys.pop(k)
      except KeyError:
        continue

    iw = I18nJsonWriter(backend_client_keys, "wave")
    # Write ios.json and android.json
    iw.write_data(env, "ios", param_prefix=r'%\1$@')
    iw.write_data(env, "android", param_prefix=r'%\1$s')

    time.sleep(5)
