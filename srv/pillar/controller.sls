PROJECT_NAME:           admin
USER_PROJECT_NAME:      demo

# OpenStack passwords
ADMIN_USER:             admin
ADMIN_PASS:             aaaf714bc418d415a898
ADMIN_ROLE:             admin
CINDER_DBNAME:          cinder
CINDER_DBPASS:          390ffbcb37603b185461
CINDER_USER:            cinder
CINDER_PASS:            c35ae663ef1837ee7849
CINDER_LOCKPATH:        /var/lib/cinder/tmp
DASH_DBPASS:            96fe9554c1cf8473bd8e
DEMO_PASS:              eed3bfbdaee76f8e2761
GLANCE_DBNAME:          glance
GLANCE_DBUSER:          glance
GLANCE_DBPASS:          a0b206e9b8978ff29311
GLANCE_USER:            glance
GLANCE_GROUP:           glance
GLANCE_PASS:            e2f8d27a76071c7d0fcb
GLANCE_SERVICE:         glance
GLANCE_DATADIR:         /var/lib/glance/images/
KEYSTONE_DBNAME:        keystone
KEYSTONE_DBUSER:        keystone
KEYSTONE_DBPASS:        32fb526e67b0a771ac98
KEYSTONE_USER:          keystone
KEYSTONE_GROUP:         keystone
METADATA_SECRET:        12960a12ad9b1ec42c8f
NEUTRON_DBNAME:         neutron
NEUTRON_DBUSER:         neutron
NEUTRON_DBPASS:         eda2d769477c07a09823
NEUTRON_USER:           neutron
NEUTRON_GROUP:          neutron
NEUTRON_PASS:           9794a532fe8d5f904c95
NOVA_API_DBNAME:        nova_api
NOVA_CELL0_DBNAME:      nova_cell0
NOVA_DBNAME:            nova
NOVA_DBUSER:            nova
NOVA_DBPASS:            c3fb240f9fffd5e667b3
NOVA_USER:              nova
NOVA_GROUP:             nova
NOVA_PASS:              5b8c138278a818058258
NOVA_LOCKPATH:          /var/lib/nova/tmp
PLACEMENT_USER:         placement
PLACEMENT_PASS:         1b2e994ebea27d11db81
RABBIT_PASS:            a62ad6014f8a305a02b5
SWIFT_USER:             swift
SWIFT_PASS:             qui1shaht9Ohtum3aiFo
SWIFT_SERVICE:          swift
USER_USER:              demo
USER_PASS:              password
USER_ROLE:              user

PROVIDER_INTERFACE_NAME:      enp0s9

{% set mgmt_ip4_controller    = '192.168.100.151' %}
{% set vms_ip4_controller     = '192.168.101.151' %}
{% set mgmt_ip4_compute       = '192.168.100.152' %}
{% set vms_ip4_compute        = '192.168.101.152' %}
{% set mgmt_ip4_block         = '192.168.100.153' %}
{% set vms_ip4_block          = '192.168.101.153' %}
{% set mgmt_ip4_object        = '192.168.100.154' %}
{% set vms_ip4_object         = '192.168.101.154' %}
{% set dnsname_controller     = 'controller' %}
{% set dnsname_compute        = 'compute' %}
{% set dnsname_block          = 'block' %}
{% set dnsname_object         = 'object' %}

mgmt_ip4_controller:          {{ mgmt_ip4_controller }}
mgmt_ip4_compute:             {{ mgmt_ip4_compute }}
mgmt_ip4_block:               {{ mgmt_ip4_block }}
mgmt_ip4_object:              {{ mgmt_ip4_object }}
dnsname_controller:           {{ dnsname_controller }}

mgmt_network:                 192.168.100.0/24
vms_network:                  192.168.101.0/24

# chrony
ntpserver:                    ntp.cesnet.cz

# /etc/hosts file
etchosts:
  127.0.0.1:                  localhost localhost.localdomain localhost4 localhost4.localdomain4
  {{ mgmt_ip4_controller }}:  {{ dnsname_controller }}
  {{ mgmt_ip4_compute }}:     {{ dnsname_compute }}
  {{ mgmt_ip4_block }}:       {{ dnsname_block }}
  {{ mgmt_ip4_object }}:      {{ dnsname_object }}

# mariadb
MARIADB_ROOTUSER:             root
MARIADB_ROOTPASSWORD:         noot5gushaeD1zaephah
mariadb_openstack_cnf:
  bind-address:               {{ mgmt_ip4_controller }}
  max_connections:            4096

# memcached
memcached:
  port:                       11211
  user:                       memcached
  maxconn:                    1024
  cachesize:                  64
  options:                    -l 127.0.0.1,::1,{{ mgmt_ip4_controller }}

# httpd
httpd:
  ServerName:                 {{ dnsname_controller }}
  Port:                       80

# cinder
cinder_logdir:                /var/log/cinder

# swift
swift:
  object_storage:             sdb
  number_of_replica:          1
