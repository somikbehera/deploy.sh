---
title: Hacking Nova in LXC
layout: default
---

# This document is a work in progress.  Please don't follow it if you don't understand what it does

[Hacking nova](hacking-nova.html) covers how to use develop nova.  This guide is how to develop within an LXC container, so you can minimize the packages installed on your ubuntu system.

### Preqequisites

* Ubuntu Maverick or Natty __64bit__

Each container gets its own process space, ip address, and filesystem - minimizing disruption to your linux desktop/server if needs to be used for purposes besides openstack.

## Install LXC

LXC is a wrapper around cgroups, chroot and debootstrap which makes creating non-virtualized environments in linux easy to create.

As root:

    apt-get install lxc vlan bridge-utils python-software-properties screen
    mkdir -p /cgroup
    echo "none /cgroup cgroup defaults 0 0" >> /etc/fstab
    mount /cgroup

## Configure Networking

Your linux box is probably configured via DHCP using WiFi or ethernet.  Your network configuration will need to be changed from eth0 being dhcp to manual.  In addition you will need to add a bridge.

### BEFORE /etc/network/interfaces

    auto lo
    iface lo inet loopback
    
    auto eth0
    iface eth0 inet dhcp

### AFTER /etc/network/interfaces

    auto lo
    iface lo inet loopback
    
    auto eth0
    iface eth0 inet manual
    
    auto br0
    iface br0 inet dhcp
      bridge_ports eth0
      bridge_stp off
      bridge_maxwait 0
      post-up /usr/sbin/brctl setfd br0 0

Now you must restart networking (your network may drop)

    /etc/init.d/networking restart

### LXC container network configuration

LXC containers are created from a template and networking configuration.  LXC comes with several templates, we need to add a network configuration that matches our system.  To do this we will create a file called /var/lib/lxc/net.conf 

    lxc.network.type=veth
    lxc.network.link=br0
    lxc.network.flags=up

## Creating & Using Containers

At this point you are ready to create your first container.  Since containers take over the current console, we recommend starting them within a screen.


    cd /var/lib/lxc
    screen -x

The first time you create a container it takes a while, additional containers only take a second to create.  The following will create and start a container called __hacking__ using the maverick template.  Note: if you are already using maverick you will need to use a template called ubuntu.

    lxc-create -n hacking -t maverick -f net.conf
    lxc-start -n hacking 

While starting you will see output similar to:

    init: plymouth main process (5) killed by ABRT signal
    init: plymouth-splash main process (206) terminated with status 2
     * Setting up resolvconf...
       ...done.
    init: plymouth-stop pre-start process (304) terminated with status 1
    
    Ubuntu 10.10 hacking /dev/console
    
    hackign login: init: ssh main process (39) terminated with status 255
    
    Ubuntu 10.10 hacking /dev/console

### Logging In

At this point if you hit enter, you will be asked to login.  The username/password is root/root.
    
    hacking login: root
    Password: 
    Linux hacking 2.6.38-8-generic #42-Ubuntu SMP Mon Apr 11 03:31:24 UTC 2011 x86_64 GNU/Linux
    Ubuntu 10.10
    
    Welcome to Ubuntu!
     * Documentation:  https://help.ubuntu.com/
    
    The programs included with the Ubuntu system are free software;
    the exact distribution terms for each program are described in the
    individual files in /usr/share/doc/*/copyright.
    
    Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
    applicable law.
    
    root@hacking:~# 

### OPTIONAL: Use apt-cacher

To serve a cached apt-repo from your host system you can setup apt-cacher:

    apt-get install apt-cacher
    echo "path_map = debian ftp.uni-kl.de/pub/linux/debian ftp2.de.debian.org/debian ; ubuntu archive.ubuntu.com/ubuntu ; security security.debian.org/debian-security ftp2.de.debian.org/debian-security" >> /etc/apt-cacher/apt-cacher.conf
    echo "AUTOSTART=1" > /etc/default/apt-cacher
    /etc/init.d/apt-cacher restart

Then on your containers update your source list to point to your server before you use apt.

    echo "deb http://192.168.2.2:3142/ubuntu maverick main universe" > /etc/apt/sources.list

### Getting Started

The container is pretty bare-bones (no sudo, curl, wget, ...).  

    apt-get update
    apt-get install -y vim curl wget sudo

Nova needs open-iscsi, which fails to install in the maverick template without creating a directory:

    mkdir /lib/init/rw/sendsigs.omit.d/

If you then follow the instructions on [hacking nova](hacking-nova.html) you will end up with an install of nova using screen within a screen.  To fix this frustration you can install __openssh-server__ add your SSH key to this machine.  Then create a new terminal and ssh directly into the container.

### Turning off the container

**Make sure you are inside the container - otherwise this will turn off your system!**

    shutdown -h now

### Multiple Containers

To add additional containers you can use screen to go to create console

    <ctrl-a> <ctrl-c>

Then create a new container

    lxc-create -n idea -t maverick -f net.conf
    lxc-start -n idea

At this point you can switch between screens, using as many containers as you wish.

    <ctrl-a> "


