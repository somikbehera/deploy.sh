#!/usr/bin/env bash
set -o errexit

#apt-get install libvirt0=0.8.3-1ubuntu14.1 libvirt-bin=0.8.3-1ubuntu14.1 python-libvirt=0.8.3-1ubuntu14.1
apt-get install libvirt0 libvirt-bin python-libvirt

curl -O https://github.com/cloudbuilders/deploy.sh/raw/master/nova.sh
chmod 755 nova.sh

export USE_GIT=1
export ENABLE_VOLUMES=0
export ENABLE_DASH=1
export ENABLE_GLANCE=1
export ENABLE_KEYSTONE=1
export NET_MAN=FlatDHCPManager

./nova.sh branch
./nova.sh install
./nova.sh run_detached
