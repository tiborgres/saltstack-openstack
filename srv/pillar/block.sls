CINDER_DBNAME:                cinder
CINDER_DBPASS:                390ffbcb37603b185461
CINDER_USER:                  cinder
CINDER_GROUP:                 cinder
CINDER_PASS:                  c35ae663ef1837ee7849
CINDER_LOCKPATH:              /var/lib/cinder/tmp
PLACEMENT_USER:               placement
PLACEMENT_PASS:               1b2e994ebea27d11db81
RABBIT_PASS:                  a62ad6014f8a305a02b5

{% set mgmt_ip4_controller    = '192.168.100.151' %}
{% set vms_ip4_controller     = '192.168.101.151' %}
{% set mgmt_ip4_compute       = '192.168.100.152' %}
{% set vms_ip4_compute        = '192.168.101.152' %}
{% set mgmt_ip4_block         = '192.168.100.153' %}
{% set vms_ip4_block          = '192.168.101.153' %}
{% set mgmt_ip4_object1       = '192.168.100.154' %}
{% set vms_ip4_object1        = '192.168.101.154' %}
{% set mgmt_ip4_object2       = '192.168.100.155' %}
{% set vms_ip4_object2        = '192.168.101.155' %}
{% set mgmt_ip4_object3       = '192.168.100.156' %}
{% set vms_ip4_object3        = '192.168.101.156' %}
{% set dnsname_controller     = 'controller' %}
{% set dnsname_compute        = 'compute' %}
{% set dnsname_block          = 'block' %}
{% set dnsname_object1        = 'object1' %}
{% set dnsname_object2        = 'object2' %}
{% set dnsname_object3        = 'object3' %}

mgmt_ip4_controller:          {{ mgmt_ip4_controller }}
mgmt_ip4_block:               {{ mgmt_ip4_block }}
dnsname_controller:           {{ dnsname_controller }}

# /etc/hosts file
etchosts:
  127.0.0.1:                  localhost localhost.localdomain localhost4 localhost4.localdomain4
  {{ mgmt_ip4_controller }}:  {{ dnsname_controller }}
  {{ mgmt_ip4_compute }}:     {{ dnsname_compute }}
  {{ mgmt_ip4_block }}:       {{ dnsname_block }}
  {{ mgmt_ip4_object1 }}:     {{ dnsname_object1 }}
  {{ mgmt_ip4_object2 }}:     {{ dnsname_object2 }}
  {{ mgmt_ip4_object3 }}:     {{ dnsname_object3 }}

osdevice:                     sda
lvmdevice:                    sdb
vgname:                       vg_cinder
