#!/bin/bash
set -e -u

cur_dir=$(cd $(dirname $0) && pwd)
config_dir=${cur_dir}/config

cd ${GIRDER_DIR}

pgrep mongod && { echo "Please close mongod"; exit 1; }

# Should have a fresh database folder.
if [[ -d /data/db/journal ]]; then
    echo "Removing database"
    rm -rf /data/db/*
fi

# Start in the background.
mongod &
job=$!

python ./tests/setup_database.py ${config_dir}/mock.yml

# Now kill the job.
kill -s STOP ${job}
# wait ${job}  # How to make this work?

echo "[ Done ]"
