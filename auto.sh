#!/usr/bin/env bash
set -o errexit

curl -O https://github.com/cloudbuilders/deploy.sh/raw/master/nova.sh
chmod 755 nova.sh

export USE_GIT=1         # checkout source using github mirror
export ENABLE_VOLUMES=0  # disable volumes
export ENABLE_DASH=1     # install & configure dashboard
export ENABLE_KEYSTONE=1 # install & configure keystone (unified auth)

./nova.sh branch
./nova.sh install
./nova.sh run # FIXME - there is a way to run this in detached mode
