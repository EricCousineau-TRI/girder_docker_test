#!/bin/bash

cur_dir=$(dirname $0)
config_dir=${cur_dir}/config

cd ${GIRDER_DIR}

python ./tests/setup_database.py ${config_dir}/mock.yml
