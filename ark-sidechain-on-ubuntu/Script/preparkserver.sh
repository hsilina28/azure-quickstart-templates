#!/bin/bash
apt-get -y update && apt-get -y install libpq-dev build-essential libtool autoconf automake zip unzip htop nmon iftop pkg-config libcairo2-dev libgif-dev jq
apt-get -y install postgresql postgresql-contrib && sudo reboot
