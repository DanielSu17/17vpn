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
    "zh_TW":    "tw",
    "zh_CN":    "cn",
    "ja":       "jp",
    "en":       "en",
    "en_US":    "en_US",
    "ar":       "ar",
    "zh_HK":    "hk",
}

class I18nJsonWriter:

    # json pretty
    indent = 2
    sort_keys = True
    separators=(',', ': ')

    # file related
    path = "../envs/%s/%s/i18n/%s/%s.json"

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


def merge_i18nkeys(i18nkeys1, i18nkeys2):
    merged_keys = {}
    for language, keys in i18nkeys2.iteritems():
        if language not in i18nkeys1:
            merged_keys[language] = keys
            continue

        temp = keys
        temp.update(i18nkeys1[language])
        merged_keys[language] = temp
    return merged_keys


def duplicate_key_exist(i18nkeys1, i18nkeys2):
    # because all the key names under each language are the same in same project,
    # we check "tw" between two projects' keys is ok enough
    # ex: 17 backend:
    # {
    #     "en": {
    #         "key1",
    #         "key2"
    #     },
    #     "tw": {
    #         "key1",
    #         "key2"
    #     }
    # }

    # ex: 17 backend.internal:
    # {
    #     "en": {
    #         "key3",
    #         "key4"
    #     },
    #     "tw": {
    #         "key3",
    #         "key4"
    #     }
    # }

    keys1 = set(i18nkeys1["tw"].keys())
    keys2 = set(i18nkeys2["tw"].keys())
    return keys1 & keys2


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

    # get i18n keys from backend internal
    p_id = lc.get_project_id_by_name("17.backend.internal")
    backend_internal_keys = lc.get_all_strings(p_id)
    # change backend.internal's language value to the one matching 17.backend and 17.backend(client)
    for k, v in backend_internal_mapping.iteritems():
      try:
        backend_internal_keys[v] = backend_internal_keys.pop(k)
      except KeyError:
        continue

    # get_all_strings This method allows one request per 5 seconds
    time.sleep(5)
    
    # check if duplicate keys exist in 17.backend.internal and 17.backend(client)
    p_id = lc.get_project_id_by_name("17.backend(client)")
    backend_client_keys = lc.get_all_strings(p_id)
    duplicate_keys = list(duplicate_key_exist(backend_internal_keys, backend_client_keys))
    if len(duplicate_keys) > 0:
        sys.stderr.write("duplicate keys are found in 17.backend.internal and 17.backend(client)\n%s" %('\n'.join(duplicate_keys)))
        sys.exit(1)

    # merge 17.backend.internal and 17.backend(client)
    backend_client_keys = merge_i18nkeys(backend_internal_keys, backend_client_keys)
    iw = I18nJsonWriter(backend_client_keys, "17app")
    # Write ios.json and android.json
    iw.write_data(env, "ios", param_prefix=r'%\1$@')
    iw.write_data(env, "android", param_prefix=r'%\1$s')

    # get_all_strings This method allows one request per 5 seconds
    time.sleep(5)

    # Write backend.json
    p_id = lc.get_project_id_by_name("17.backend")
    iw = I18nJsonWriter(lc.get_all_strings(p_id), "17app")
    iw.write_data(env, "backend")

    # get_all_strings This method allows one request per 5 seconds
    time.sleep(5)
