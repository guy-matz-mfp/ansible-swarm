#!/bin/bash
GITHUB_ORGANIZATION="git@github.com:GroupM-mPlatform"

sudo yum install -y git
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
ssh -T git@github.com
mkdir -p /etc/ansible/roles
sudo chmod -R 0755 /etc/ansible
sudo chown -R vagrant:vagrant /etc/ansible
cd /etc/ansible/roles
if [ ! -z "$REPOLIST" ];
  then
    for REPO in $REPOLIST; do
      cd /etc/ansible/roles/
      mkdir -p /etc/ansible/roles/${REPO}
      cd /etc/ansible/roles/${REPO}
      git init .
      git remote add origin ${GITHUB_ORGANIZATION}/${REPO}
      git pull origin master
    done
  else
    echo "\$REPOLIST is empty"
fi
sudo chown -R vagrant:vagrant /etc/ansible
