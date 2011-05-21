---
title: Experimenting with Dashboard
layout: default
---

We are in the process of thinking about about dashboards for OS - what better way to think than to hack!  Beware that the dashboard branch being referred to here is not stable atm, and will be undergoing much change.

Some of our objectives include:

* Use of OS API
* Exploring administrative features
* Experimenting with UI
* and more...

To get started, grab the code:

    git clone git://github.com/sleepsonthefloor/openstackAPI.git

Then update your local_settings.py.  For starters, just copy over local_settings.py.example

    cd openstackAPI/openstack-dashboard
    cp local/local_settings.py.example local/local_settings.py

For local development, first create a virtualenv for local development.  A tool is included to create one for you:

    python tools/install_venv.py

Now, issue the django syncdb command:

    tools/with_venv.sh dashboard/manage.py syncdb

If after you have specified the admin user the script appears to hang, it
probably means the installation of Nova being referred to in local_settings.py
is unavailable.

If all is well you should now able to run the server locally:

    tools/with_venv.sh dashboard/manage.py runserver



