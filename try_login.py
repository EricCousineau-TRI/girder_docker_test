#!/usr/bin/env python

import json
from base64 import b64encode
import subprocess

def subshell(cmd, strip=True):
    output = subprocess.check_output(cmd, shell=isinstance(cmd, str))
    if strip:
        return output.strip()
    else:
        return output

auth = b64encode("admin:password")
url = "http://localhost:8080"
api_url = url + "/api/v1"

response = subshell([
    "curl", "-X", "GET", "-s",
        "--header", "Accept: application/json",
        "--header", "Authorization: Basic {}".format(auth),
    "{}/user/authentication".format(api_url)])

token = json.loads(response)['authToken']['token']

def get(endpoint, args = []):
    response = subshell([
        "curl", "-X", "GET", "-s",
            "--header", "Accept: application/json",
            "--header", "Girder-Token: {}".format(token)] + args +
        ["{}{}".format(api_url, endpoint)])
    return json.loads(response)

api_key = get('/api_key')[0]['key']

def get_folder_id(collection_name):
    parent_id = get('/collection?text={}'.format(collection_name))[0]["_id"]
    folder_id = get('/folder?parentType=collection&parentId={}'.format(parent_id))[0]["_id"]
    return folder_id

# Get folder ids.
print(get_folder_id('devel'))
print(get_folder_id('master'))
print(get_folder_id('private'))
