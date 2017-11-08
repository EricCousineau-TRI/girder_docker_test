#!/bin/bash
set -e -u

docker build -t girder-dev -f ./Dockerfile.girder-dev .
docker build -t girder_mongodb -f ./Dockerfile .
