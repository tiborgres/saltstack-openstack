#!/bin/bash

yum -y erase mariadb\* rabbitmq\* openstack\*
rm -rf /var/lib/mysql /var/lib/rabbitmq
