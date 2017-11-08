#!/usr/bin/env python

import sys
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
url = sys.argv[1]
api_url = url + "/api/v1"

response = subshell([
    "curl", "-X", "GET", "-s",
        "--header", "Accept: application/json",
        "--header", "Authorization: Basic {}".format(auth),
    "{}/user/authentication".format(api_url)])

token = json.loads(response)['authToken']['token']

def get(endpoint, args = [], mode = "GET"):
    extra_args = []
    if mode == "POST":
        # https://serverfault.com/a/315852/443276
        extra_args += ["-d", ""]
    response = subshell([
        "curl", "-X", mode, "-s",
            "--header", "Accept: application/json",
            "--header", "Girder-Token: {}".format(token)] + args + extra_args +
        ["{}{}".format(api_url, endpoint)])
    return json.loads(response)

api_key = get('/api_key?active=true', mode = "POST")['key']

def get_folder_id(collection_name):
    parent_id = get('/collection?text={}'.format(collection_name))[0]["_id"]
    folder_id = get('/folder?parentType=collection&parentId={}'.format(parent_id))[0]["_id"]
    return folder_id

# Get folder ids.
devel_id = get_folder_id('devel')
master_id = get_folder_id('master')
private_id = get_folder_id('private')

# Dump information
import yaml

info = {
    "url": url,
    "api_key": str(api_key),
    "folders": {
        "master": str(master_id),
        "devel": str(devel_id),
        "private": str(private_id),
    },
}
print(yaml.dump(info, default_flow_style=False))
