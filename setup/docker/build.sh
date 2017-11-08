#!/bin/bash
set -e -u

cd $(dirname $0)
docker build -t girder-dev -f ./Dockerfile.girder-dev .
docker build -t girder_mongodb -f ./Dockerfile .

docker build -t external_data_test -f ./Dockerfile.external_data .

cat <<EOF

For running:

    cd test_with_girder
    docker rm -f girder_mongodb_c || :
    docker run --name girder_mongodb_c --entrypoint bash --detach -t -p 8080:8080 -v ~+:/mnt girder_mongodb
    docker exec -it girder_mongodb_c bash

EOF
