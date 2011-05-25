#!/usr/bin/env bash
set -o errexit

curl -O https://github.com/cloudbuilders/deploy.sh/raw/master/nova.sh
chmod 755 nova.sh

export USE_GIT=1
export ENABLE_VOLUMES=0
export ENABLE_DASH=1
export ENABLE_GLANCE=1
export ENABLE_KEYSTONE=1

./nova.sh branch
./nova.sh install
./nova.sh run_detached
