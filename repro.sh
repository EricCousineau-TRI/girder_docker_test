#!/bin/bash
set -e -u

# Unable to get the same results as instructions:
# http://girder.readthedocs.io/en/latest/developer-cookbook.html#authenticating-to-the-web-api

cd $(cd $(dirname $0) && pwd)

./setup/docker/build.sh
container=$(docker run --entrypoint bash --detach --rm -t -p 8080:8080 -v ~+:/mnt girder_mongodb)
echo -e "container:\n${container}"
docker exec -t ${container} /mnt/run_import.sh
docker exec -t ${container} bash -c "{ mongod& } && girder-server" > /dev/null &

echo "[ Waiting ... ]"
sleep 2

echo "[ Try login ]"
./try_login.py

echo "[ Stopping (and removing) ]"
docker stop ${container}
