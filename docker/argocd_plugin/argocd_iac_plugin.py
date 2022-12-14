#!/usr/bin/env python3
import re
import os
import sys
import base64
import traceback

import urllib3
import subprocess

import requests
from kubernetes import client, config


DEBUG = os.environ.get("AVP_DEBUG") == 'yes'
AVP_ROLE_ID = os.environ.get('AVP_ROLE_ID')
AVP_SECRET_ID = os.environ.get('AVP_SECRET_ID')
VAULT_ADDR = os.environ.get('VAULT_ADDR')


regex_pattern = re.compile('~([^~\s]{1,100})~')
regex_format = '~{}~'


urllib3.disable_warnings()
try:
    config.load_incluster_config()
except config.ConfigException:
    try:
        config.load_kube_config()
    except config.ConfigException:
        raise Exception("Could not configure kubernetes python client")
coreV1Api = client.CoreV1Api()


def debug_log(msg, with_env=False):
    if DEBUG:
        with open('/tmp/argocd-iac-plugin.log', 'a') as f:
            f.write(f'{msg}\n')
        if with_env:
            debug_log(subprocess.check_output(['env']).decode())


def parse_matches(matches):
    parsed_matches = {}
    for match in matches:
        if match.startswith('vault'):
            match_parts = match.split(':')
            if len(match_parts) > 2:
                parse_type, vault_path, *vault_key = match.split(':')
                vault_key = ':'.join(vault_key)
                if len(vault_path) and len(vault_key):
                    parsed_matches[match] = {
                        'type': 'vault',
                        'path': vault_path,
                        'key': vault_key,
                        'output_raw': parse_type == 'vault_raw'
                    }
        if match.startswith('iac:'):
            match_parts = match.split(':')
            if len(match_parts) > 1:
                _, *key = match.split(':')
                key = ':'.join(key)
                if len(key):
                    parsed_matches[match] = {
                        'type': 'iac',
                        'key': key
                    }
    return parsed_matches


def get_vault_path_data(vault_token, path):
    url = os.path.join(VAULT_ADDR, 'v1', 'kv', path)
    return requests.get(url, headers={'X-Vault-Token': vault_token}).json()['data']


def get_iac_data(configmap='tf-outputs'):
    configmap = coreV1Api.read_namespaced_config_map(configmap, 'argocd')
    return configmap.data


def get_vault_token():
    try:
        return requests.post(
            f'{VAULT_ADDR}/v1/auth/approle/login',
            json={'role_id': AVP_ROLE_ID, 'secret_id': AVP_SECRET_ID}
        ).json()['auth']['client_token']
    except:
        debug_log(traceback.format_exc())
        return None


def get_match_values(parsed_matches):
    vault_token = get_vault_token()
    match_values = {}
    iac_data = None
    configmap_iac_data = {}
    vault_paths_data = {}
    for match, parsed_match in parsed_matches.items():
        if parsed_match['type'] == 'iac':
            if '//' in parsed_match['key']:
                configmap, key = parsed_match['key'].split('//')
                if configmap not in configmap_iac_data:
                    configmap_iac_data[configmap] = get_iac_data(configmap)
                match_values[match] = configmap_iac_data[configmap].get(key, '')
            else:
                if iac_data is None:
                    iac_data = get_iac_data()
                match_values[match] = iac_data.get(parsed_match['key'], '')
        elif parsed_match['type'] == 'vault':
            if parsed_match['path'] not in vault_paths_data:
                vault_paths_data[parsed_match['path']] = get_vault_path_data(vault_token, parsed_match['path'])
            val = vault_paths_data[parsed_match['path']].get(parsed_match['key'], '')
            if not parsed_match['output_raw']:
                val = base64.b64encode(val.encode()).decode()
            match_values[match] = val
    return match_values


def generate(chart_path, argocd_app_name, argocd_app_namespace, *helm_args):
    debug_log(
        f'generate chart_path={chart_path} argocd_app_name={argocd_app_name} '
        f'argocd_app_namespace={argocd_app_namespace} helm_args={helm_args}',
        with_env=True
    )
    yamls = subprocess.check_output(
        ['helm', 'template', argocd_app_name, '--namespace', argocd_app_namespace, *helm_args, '.'],
        cwd=chart_path
    ).decode()
    parsed_matches = parse_matches(set(re.findall(regex_pattern, yamls)))
    match_values = get_match_values(parsed_matches)
    for match, value in match_values.items():
        yamls = yamls.replace(regex_format.format(match), value)
    print(yamls)


def main(operation, *args):
    if operation == 'generate':
        generate(*args)


if __name__ == "__main__":
    main(*sys.argv[1:])
