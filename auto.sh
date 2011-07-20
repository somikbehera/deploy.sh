#!/usr/bin/env bash
set -o errexit

NOVASCRIPT=${NOVASCRIPT:-nova.sh}
curl -O https://raw.github.com/cloudbuilders/deploy.sh/master/$NOVASCRIPT
chmod 755 $NOVASCRIPT

export USE_GIT=1
export ENABLE_VOLUMES=0
export ENABLE_DASH=1
export ENABLE_GLANCE=1
export ENABLE_KEYSTONE=1
export ENABLE_APACHE=1
export NET_MAN=FlatDHCPManager

./$NOVASCRIPT branch
./$NOVASCRIPT install

# HACK: cloud servers requires older libvirt
if [ ! -z "$CLOUDSERVER" ] ; then
    apt-get install -y --force-yes libvirt0=0.8.3-1ubuntu18 libvirt-bin=0.8.3-1ubuntu18 python-libvirt=0.8.3-1ubuntu18
fi

./$NOVASCRIPT run_detached
