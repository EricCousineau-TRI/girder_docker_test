#!/bin/bash
set -e -u

cur_dir=$(cd $(dirname $0) && pwd)
config_dir=${cur_dir}/config
girder_dir=${GIRDER_DIR:-/girder}
db_dir=/data/db

cd ${girder_dir}

pgrep mongod && { echo "Please close mongod"; exit 1; }

# Should have a fresh database folder.
if [[ -d ${db_dir}/journal ]]; then
    echo "Removing database"
    rm -rf ${db_dir}/*
fi

# Start in the background.
mongod &
job=$!

python ./tests/setup_database.py ${config_dir}/mock.yml

# Now kill the job.
kill -s INT ${job}
wait ${job}

echo "[ Done ]"
