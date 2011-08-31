#!/usr/bin/env bash
set -o errexit

NOVASCRIPTURL=${NOVASCRIPTURL:-https://raw.github.com/cloudbuilders/deploy.sh/master/nova.sh}
curl -O $NOVASCRIPTURL

NOVASCRIPT="$(echo -n $NOVASCRIPTURL | sed -e 's/.*\///')"
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
    apt-get install -y --force-yes libvirt0=0.8.3-1ubuntu19.1 libvirt-bin=0.8.3-1ubuntu19.1 python-libvirt=0.8.3-1ubuntu19.1
fi

./$NOVASCRIPT run_detached
