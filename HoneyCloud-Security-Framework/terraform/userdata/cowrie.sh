#!/bin/bash

apt update -y
apt install -y git python3 python3-pip python3-venv awscli docker.io

useradd -m cowrie

cd /home/cowrie

git clone https://github.com/cowrie/cowrie.git

chown -R cowrie:cowrie /home/cowrie/cowrie

su - cowrie -c '
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
cp etc/cowrie.cfg.dist etc/cowrie.cfg
bin/cowrie start
'