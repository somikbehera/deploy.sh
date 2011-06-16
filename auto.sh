#!/usr/bin/env bash
set -o errexit

curl -O https://raw.github.com/cloudbuilders/deploy.sh/master/nova.sh
chmod 755 nova.sh

export USE_GIT=1
export ENABLE_VOLUMES=0
export ENABLE_DASH=1
export ENABLE_GLANCE=1
export ENABLE_KEYSTONE=1
export ENABLE_APACHE=1
export NET_MAN=FlatDHCPManager

./nova.sh branch
./nova.sh install

# HACK: cloud servers requires older libvirt
if [ ! -z "$CLOUDSERVER" ] ; then
    apt-get install -y --force-yes libvirt0=0.8.3-1ubuntu18 libvirt-bin=0.8.3-1ubuntu18 python-libvirt=0.8.3-1ubuntu18
fi

./nova.sh run_detached
