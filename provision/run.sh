#!/bin/bash

cat << HOSTS > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.100.151	controller
192.168.100.152	compute
192.168.100.153	block
192.168.100.154	object
HOSTS

cat << REPO > /etc/yum.repos.d/saltstack.repo
[saltstack-repo]
name=SaltStack repo for Red Hat Enterprise Linux $releasever
baseurl=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest/SALTSTACK-GPG-KEY.pub
       https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest/base/RPM-GPG-KEY-CentOS-7
REPO

yum -y install salt-minion
cd /etc
rm -rf salt
ln -s /vagrant/etc/salt-$HOSTNAME salt
systemctl restart salt-minion.service

