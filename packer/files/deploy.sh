#!/bin/bash
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
apt update
apt install -y ruby-full ruby-bundler build-essential mongodb-org
systemctl enable mongod
mkdir /var/www && cd /var/www
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
mv /tmp/puma.service /etc/systemd/system/puma.service
systemctl daemon-reload
systemctl enable puma

