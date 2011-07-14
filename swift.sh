#!/usr/bin/env bash
set -e
set -x

LOOPBACK_DISK_SIZE=1000000
USER=root
GROUP=root
DEBIAN_FRONTEND=noninteractive
SWIFT_HASH=swift-stack3rs
MY_IP=$(curl -s http://icanhazip.com/)
USE_RSYSLOG="yes"

export  DEBIAN_FRONTEND LOOPBACK_DISK_SIZE USER GROUP SWIFT_HASH MY_IP

function install_rsyslog() {
    apt-get -y install rsyslog
    cat <<EOF>/etc/rsyslog.d/10-swift.conf
# Uncomment the following to have a log containing all logs together
#local1,local2,local3,local4,local5.*   /var/log/swift/all.log

# Uncomment the following to have hourly proxy logs for stats processing
#$template HourlyProxyLog,"/var/log/swift/hourly/%$YEAR%%$MONTH%%$DAY%%$HOUR%"
#local1.*;local1.!notice ?HourlyProxyLog

local1.*;local1.!notice /var/log/swift/proxy.log
local1.notice           /var/log/swift/proxy.error
local1.*                ~

local2.*;local2.!notice /var/log/swift/storage1.log
local2.notice           /var/log/swift/storage1.error
local2.*                ~

local3.*;local3.!notice /var/log/swift/storage2.log
local3.notice           /var/log/swift/storage2.error
local3.*                ~

local4.*;local4.!notice /var/log/swift/storage3.log
local4.notice           /var/log/swift/storage3.error
local4.*                ~

local5.*;local5.!notice /var/log/swift/storage4.log
local5.notice           /var/log/swift/storage4.error
local5.*                ~
EOF
    sed -i  's/PrivDropToGroup syslog/PrivDropToGroup adm/' /etc/rsyslog.conf
    mkdir -p /var/log/swift/hourly
    chown -R syslog.adm /var/log/swift
    service rsyslog restart
}

apt-get -y install python-software-properties
add-apt-repository ppa:swift-core/ppa
apt-get -y update
apt-get -y install curl gcc bzr memcached python-configobj python-coverage python-dev python-nose python-setuptools python-simplejson python-xattr sqlite3 xfsprogs python-webob python-eventlet python-greenlet python-pastedeploy python-netifaces

mkdir -p /srv
dd if=/dev/zero of=/srv/swift-disk bs=1024 count=0 seek=${LOOPBACK_DISK_SIZE}
mkfs.xfs -f -i size=1024 /srv/swift-disk

cat <<EOF>>/etc/fstab
# Added by swaio
/srv/swift-disk /mnt/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0
EOF

mkdir -p /mnt/sdb1
mount /mnt/sdb1

mkdir /mnt/sdb1/1 /mnt/sdb1/2 /mnt/sdb1/3 /mnt/sdb1/4
chown -R ${USER}:${GROUP} /mnt/sdb1
for x in {1..4}; do ln -s /mnt/sdb1/$x /srv/$x; done

mkdir -p /etc/swift/object-server /etc/swift/container-server /etc/swift/account-server /srv/1/node/sdb1 /srv/2/node/sdb2 /srv/3/node/sdb3 /srv/4/node/sdb4 /var/run/swift

chown -R ${USER}:${GROUP} /etc/swift /srv/[1-4]/ /var/run/swift


sed -i '/^exit 0/d' /etc/rc.local
cat <<EOF>>/etc/rc.local
mkdir -p /var/run/swift
chown ${USER}:${GROUP} /var/run/swift
exit 0
EOF

cat <<EOF>/etc/rsyncd.conf
uid = ${USER}
gid = ${GROUP}
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 127.0.0.1

[account6012]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/account6012.lock

[account6022]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/account6022.lock

[account6032]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/account6032.lock

[account6042]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/account6042.lock


[container6011]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/container6011.lock

[container6021]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/container6021.lock

[container6031]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/container6031.lock

[container6041]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/container6041.lock


[object6010]
max connections = 25
path = /srv/1/node/
read only = false
lock file = /var/lock/object6010.lock

[object6020]
max connections = 25
path = /srv/2/node/
read only = false
lock file = /var/lock/object6020.lock

[object6030]
max connections = 25
path = /srv/3/node/
read only = false
lock file = /var/lock/object6030.lock

[object6040]
max connections = 25
path = /srv/4/node/
read only = false
lock file = /var/lock/object6040.lock
EOF

sed -i "s/^RSYNC_ENABLE=false/RSYNC_ENABLE=true/" /etc/default/rsync
service rsync restart

#TODO: logging

mkdir -p ~/bin/
bzr init-repo swift
cd ~/swift; bzr branch lp:swift trunk
cd ~/swift/trunk; python setup.py develop

cat <<EOF>>~/.bashrc
export SWIFT_TEST_CONFIG_FILE=/etc/swift/func_test.conf
export PATH=\${PATH}:~/bin
EOF

cat <<EOF>/etc/swift/proxy-server.conf
[DEFAULT]
bind_port = 8080
user = ${USER}
log_facility = LOG_LOCAL1

[pipeline:main]
pipeline = healthcheck cache tempauth proxy-server

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true

[filter:tempauth]
use = egg:swift#tempauth
user_admin_admin = admin .admin .reseller_admin
user_test_tester = testing .admin
user_test2_tester2 = testing2 .admin
user_test_tester3 = testing3
bind_ip = ${MY_IP}

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:cache]
use = egg:swift#memcache
EOF

#TODO: randomize hash_path?
cat <<EOF>/etc/swift/swift.conf
[swift-hash]
# random unique string that can never change (DO NOT LOSE)
swift_hash_path_suffix = ${SWIFT_HASH}
EOF

bind_port=6012
log_facility=2
for n in {1..4};do
    cat <<EOF>/etc/swift/account-server/${n}.conf
[DEFAULT]
devices = /srv/${n}/node
mount_check = false
bind_port = ${bind_port}
user = ${USER}
log_facility = LOG_LOCAL${log_facility}

[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account

[account-replicator]
vm_test_mode = yes

[account-auditor]

[account-reaper]
EOF
    bind_port=$(( ${bind_port} + 10 ))
    log_facility=$(( ${log_facility} + 1 ))
done

bind_port=6011
log_facility=2
for n in {1..4};do
    cat <<EOF>/etc/swift/container-server/${n}.conf
[DEFAULT]
devices = /srv/${1}/node
mount_check = false
bind_port = ${bind_port}
user = ${USER}
log_facility = LOG_LOCAL${log_facility}

[pipeline:main]
pipeline = container-server

[app:container-server]
use = egg:swift#container

[container-replicator]
vm_test_mode = yes

[container-updater]

[container-auditor]
EOF
    bind_port=$(( ${bind_port} + 10 ))
    log_facility=$(( ${log_facility} + 1 ))
done

bind_port=6010
log_facility=2
for n in {1..4};do
    cat <<EOF>/etc/swift/object-server/${n}.conf
[DEFAULT]
devices = /srv/${n}/node
mount_check = false
bind_port = ${bind_port}
user = ${USER}
log_facility = LOG_LOCAL${log_facility}

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object

[object-replicator]
vm_test_mode = yes

[object-updater]

[object-auditor]
EOF
    bind_port=$(( ${bind_port} + 10 ))
    log_facility=$(( ${log_facility} + 1 ))
done

cat <<EOF>/usr/local/bin/resetswift
#!/bin/bash

swift-init all stop
find /var/log/swift -type f -exec rm -f {} \;
sudo umount /mnt/sdb1
sudo mkfs.xfs -f -i size=1024 /dev/sdb1
sudo mount /mnt/sdb1
sudo mkdir /mnt/sdb1/1 /mnt/sdb1/2 /mnt/sdb1/3 /mnt/sdb1/4
sudo chown ${USER}:${GROUP} /mnt/sdb1/*
mkdir -p /srv/1/node/sdb1 /srv/2/node/sdb2 /srv/3/node/sdb3 /srv/4/node/sdb4
sudo rm -f /var/log/debug /var/log/messages /var/log/rsyncd.log /var/log/syslog
sudo service rsyslog restart
sudo service memcached restart
EOF

cat <<EOF>/usr/local/bin/remakerings
#!/bin/bash

cd /etc/swift

rm -f *.builder *.ring.gz backups/*.builder backups/*.ring.gz

swift-ring-builder object.builder create 18 3 1
swift-ring-builder object.builder add z1-127.0.0.1:6010/sdb1 1
swift-ring-builder object.builder add z2-127.0.0.1:6020/sdb2 1
swift-ring-builder object.builder add z3-127.0.0.1:6030/sdb3 1
swift-ring-builder object.builder add z4-127.0.0.1:6040/sdb4 1
swift-ring-builder object.builder rebalance
swift-ring-builder container.builder create 18 3 1
swift-ring-builder container.builder add z1-127.0.0.1:6011/sdb1 1
swift-ring-builder container.builder add z2-127.0.0.1:6021/sdb2 1
swift-ring-builder container.builder add z3-127.0.0.1:6031/sdb3 1
swift-ring-builder container.builder add z4-127.0.0.1:6041/sdb4 1
swift-ring-builder container.builder rebalance
swift-ring-builder account.builder create 18 3 1
swift-ring-builder account.builder add z1-127.0.0.1:6012/sdb1 1
swift-ring-builder account.builder add z2-127.0.0.1:6022/sdb2 1
swift-ring-builder account.builder add z3-127.0.0.1:6032/sdb3 1
swift-ring-builder account.builder add z4-127.0.0.1:6042/sdb4 1
swift-ring-builder account.builder rebalance
EOF

cat <<EOF>/usr/local/bin/startmain
#!/bin/bash

swift-init main start
EOF

cat <<EOF>/usr/local/bin/startrest
#!/bin/bash

swift-init rest start
EOF

chmod +x /usr/local/bin/*

[[ ${USE_RSYSLOG,,} == "yes" ]] && install_rsyslog

/usr/local/bin/remakerings

/usr/local/bin/startmain


