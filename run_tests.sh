#!/bin/bash
set -e -u

cd $(cd $(dirname $0) && pwd)

echo "[ Configure ]"
out_dir=${PWD}/build
mkdir -p ${out_dir}

repo_name=bazel-large-files-with-girder
repo_dir=${out_dir}/${repo_name}
rm -rf ${repo_dir}
cp -r ../${repo_name} ${out_dir}/

(
    cd ${repo_dir}
    git clean -fxd > /dev/null
)

# Download data files.
(
    cd ${out_dir}
    [[ -f small_dragon.obj ]] || \
        curl -L --progress-bar -o small_dragon.obj -O https://github.com/jcfr/bazel-large-files-with-girder/releases/download/test-data/small_dragon.obj
    [[ -f large_dragon.obj ]] || \
        curl -L --progress-bar -o large_dragon.obj -O https://github.com/jcfr/bazel-large-files-with-girder/releases/download/test-data/large_dragon.obj
)

echo "[ Docker Setup ]"
./setup/docker/build.sh #> /dev/null

echo "[ Server Setup (on Server) ]"
server=$(docker run --entrypoint bash --detach --rm -t -p 8080:8080 -v ~+:/mnt girder_mongodb)
echo -e "server:\n${server}"
docker exec -t ${server} /mnt/setup_server.sh > /dev/null
docker exec -t ${server} bash -c "{ mongod& } && girder-server" > /dev/null &

# https://stackoverflow.com/a/20686101/7829525
ip_addr=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${server})

# Use HTTP - https://serverfault.com/a/861580/443276
url="http://${ip_addr}:8080"

# Wait for server to initialize.
sleep 2

echo "[ Client Setup (on Host) ]"
info_file=${out_dir}/info.yaml
config_file=${repo_dir}/.external_data.yml
user_file=${out_dir}/external_data.user.yml
./setup_client.py ${url} ${info_file} ${config_file} ${user_file}

echo "[ Run Tests (on Client) ]"
client=$(docker run --detach --rm -t -v ~+:/mnt external_data_test)
docker exec -t ${client} /mnt/test_client.sh

echo "[ Stopping (and removing) ]"
docker stop ${server} ${client}
