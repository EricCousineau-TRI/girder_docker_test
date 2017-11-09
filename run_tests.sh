#!/bin/bash
set -e -u

cd $(cd $(dirname $0) && pwd)

out_dir=${PWD}/build

mkdir -p ${out_dir}

./setup/docker/build.sh > /dev/null

echo "[ Configure ]"

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

config_file=${repo_dir}/.external_data.yml
out_file=${out_dir}/info.yaml
user_file=${out_dir}/external_data.user.yml

# Initialize server.
server=$(docker run --entrypoint bash --detach --rm -t -p 8080:8080 -v ~+:/mnt girder_mongodb)
echo -e "server:\n${server}"
docker exec -t ${server} /mnt/setup_server.sh > /dev/null
docker exec -t ${server} bash -c "{ mongod& } && girder-server" > /dev/null &

# https://stackoverflow.com/a/20686101/7829525
ip_addr=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${server})

# Use HTTP - https://serverfault.com/a/861580/443276
url="http://${ip_addr}:8080"

echo "[ Try login ]"
sleep 2
./setup_client.py "${url}" ${out_file}

echo "[ Generate config stuff ]"

python - <<EOF
import yaml

info_file = "${out_file}"
config_file = "${config_file}"
user_file = "${user_file}"

info = yaml.load(open(info_file))
config = yaml.load(open(config_file))

print(info)
print(config)

url = info["url"]

# Write updated config
remotes = config["remotes"]
remotes["master"]["folder_id"] = info["folders"]["master"]
remotes["master"]["url"] = url
remotes["devel"]["folder_id"] = info["folders"]["devel"]
remotes["devel"]["url"] = url
remotes["devel"]["overlay"] = "master"
config["remote"] = "devel"
with open(config_file, 'w') as f:
    yaml.dump(config, f, default_flow_style=False)

# Generate the user config.
user_config = {
    "girder": {
        "url": {
            url: {
                "api_key": info["api_key"]
            },
        },
    },
}
with open(user_file, 'w') as f:
    yaml.dump(user_config, f, default_flow_style=False)
print("Done")
EOF

client=$(docker run --detach --rm -t -v ~+:/mnt external_data_test)
docker exec -t ${client} /mnt/test_client.sh

# echo "[ Stopping (and removing) ]"
# docker stop ${server}
# docker stop ${client}
