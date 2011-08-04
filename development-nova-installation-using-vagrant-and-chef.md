---
title: single node nova installation using vagrant and chef
layout: default
---

Integration testing for distributed systems that have many dependencies can be a huge challenge.  Ideally, you would have a cluster of machines that you could PXE boot to a base os install and run a complete install of the system.  Unfortunately not everyone has a bunch of extra hardware sitting around.  For those of us that are a bit on the frugal side, a whole lot of testing can be done with Virtual Machines.  Read on for a simple guide to installing Nova with VirtualBox and Vagrant.

###Installing VirtualBox

VirtualBox is virtualization software by Oracle.  It runs on Mac/Linux/Windows and can be controlled from the command line.  Note that we will be using VirtualBox 4.0 and the vagrant prerelease.

#### OSX

    curl -OL http://download.virtualbox.org/virtualbox/4.1.0/VirtualBox-4.1.0-73009-OSX.dmg
    open VirtualBox-4.1.0-73009-OSX.dmg
    # click through the installer

#### Maverick

    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
    echo "deb http://download.virtualbox.org/virtualbox/debian maverick contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    sudo apt-get update
    sudo apt-get install -y virtualbox-4.0

#### Lucid

    wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
    echo "deb http://download.virtualbox.org/virtualbox/debian lucid contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    sudo apt-get update
    sudo apt-get install -y virtualbox-4.0


#### Grab the code:

    cd ~
    mkdir bzr
    cd bzr
    bzr init-repo .
    bzr branch lp:nova trunk

### Setup for running tests on Lion

If you want to run the tests on OSX Lion, you can get there using this section. If you aren't using OSX, or don't care about running tests, you can skip this part.

##### Install m2crypto

    curl -O http://chandlerproject.org/pub/Projects/MeTooCrypto/M2Crypto-0.21.1-py2.7-macosx-10.7-intel.egg
    sudo easy_install M2Crypto-0.21.1-py2.7-macosx-10.7-intel.egg

##### Install Other Dependencies

    cd trunk
    sed "s/M2Crypto==0.20.2/M2Crypto>=0.20.2/" tools/pip-requires > tools/pip-lion
    sudo pip install -r tools/pip-lion

##### Install euca2ools

    curl -O http://eucalyptussoftware.com/downloads/releases/euca2ools-1.3.1.tar.gz
    tar -zxvf euca2ools-1.3.1.tar.gz
    cd euca2ools-1.3.1
    sudo make install

##### Install python-novaclient

    git clone https://github.com/rackspace/python-novaclient
    cd python-novaclient
    sudo python setup.py develop

##### Run the Tests

    ./run_tests.sh -N


### Get Vagrant

_Prerelease version no longer necessary. The current version of vagrant (0.8) works fine._

#### OSX

    sudo gem update --system
    sudo gem install vagrant

#### Maverick

    sudo gem install vagrant
    sudo ln -s /var/lib/gems/1.8/bin/vagrant /usr/local/bin/vagrant

#### Lucid

    wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.6.zip
    sudo apt-get install -y unzip
    unzip rubygems-1.3.6.zip
    cd rubygems-1.3.6
    sudo ruby setup.rb
    sudo gem1.8 install vagrant

### Get the chef recipes

    cd ~
    git clone http://github.com/cloudbuilders/openstack-cookbooks.git

### Set up some directories

    mkdir aptcache
    mkdir -p vagrant/dev
    cd vagrant/dev

#### Get the nova source Vagrantfile

Provisioning for vagrant can use chef-solo, chef-server, or puppet.  We're going to use chef-solo for the installation of nova.

    curl -o Vagrantfile https://raw.github.com/gist/786945/source.rb

### Running nova

Installing and running nova is as simple as vagrant up

    vagrant up

In 3-10 minutes, your vagrant instance should be running.
NOTE: Some people report an error from vagrant complaining about MAC addresses the first time they vagrant up.  Doing vagrant up again seems to resolve the problem.

    vagrant ssh

My settings use tmux by default. My tmux settings are set up to use the same keyboard shortcuts as screen, so you should be at home if you have used screen before. If you don't like my settings, you can always disable them by commenting out the line in the Vagrantfile that refers to "recipe[anso::settings]",

Now you can run an instance and connect to it:

    . /vagrant/novarc
    euca-add-keypair test > test.pem
    chmod 600 test.pem
    euca-run-instances -t m1.tiny -k test ami-tty
    # wait for boot (euca-describe-instances should report running)
    ssh -i test.pem root@10.0.0.3

Yo, dawg, your VMs have VMs!  That is, you are now running an instance inside of Nova, which itself is running inside a VirtualBox VM.

This script uses github.com/vishvananda/novascript which runs all of the nova workers in screen.  There is a brief description of nova.sh in /tmp/novascript/README.md . You can connect to the running screen with:

    sudo screen -x

The source code is in /tmp/bzr/nova

When you are finished, you can destroy the entire system with vagrant destroy. You can also leave the box running and use it again later.

    vagrant destroy

### Running a different branch

You can kill the running nova and restart from a different branch like so:

    cd /tmp/bzr
    sudo ../novascript/nova.sh terminate
    sudo ../novascript/nova.sh clean
    sudo ../novascript/nova.sh run <branch>

If you get stuck you can also recreate the entire vm using a different branch:

    vagrant destroy
    export SOURCE_BRANCH=<some_branch>; vagrant up
