---
title: All In One
layout: default
---

# Cloud Builder Documentation

## scripts

### lxc + ubuntu powered demo/testing deployment:

From a base maverick install, use LXC to configure a multi-mode openstack deployment using:

 * DHCP: pxe + preseed, tftp, dnsmasq
 * CHEF: chef-server, openstack recipes

        curl -Sks https://github.com/cloudbuilders/deploy.sh/raw/master/setup.sh | /bin/bash

