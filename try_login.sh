#!/bin/bash
set -e -u

auth=$(echo -n admin:password | base64)

url=http://localhost:8080

set -x
curl -X GET \
    --header "Accept: application/json" \
    --header "Authorization: Basic ${auth}" \
     ${url}/api/v1/user/authentication
echo
