# /etc/hosts
/etc/hosts:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.hosts.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

centos-release-openstack-pike:
  pkg.installed

python2-openstackclient:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

# mariadb
python2-PyMySQL:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

mariadb-server:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - name: mariadb
    - enable: true
    - reload: true
    - require:
      - file: /etc/my.cnf.d/openstack.cnf
    - watch:
      - file: /etc/my.cnf.d/openstack.cnf
    - onchanges_in:
      - cmd: mysql secure script

/etc/my.cnf.d/openstack.cnf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/mariadb_openstack.cnf.template
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: mariadb-server
    - watch_in:
      - service: mariadb-server

mysql secure script:
  cmd.run:
    - name: echo -e "\n\n{{ salt['pillar.get']('MARIADB_ROOTPASSWORD') }}\n{{ salt['pillar.get']('MARIADB_ROOTPASSWORD') }}\n\n\nn\n\n " | mysql_secure_installation
    - onchanges:
      - service: mariadb-server

/root/.my.cnf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/root.my.cnf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600
    - require:
      - cmd: mysql secure script

# chrony
chrony:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - name: chronyd
    - enable: True
    - require:
      - pkg: chrony

/etc/chrony.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/chrony.conf.template
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: chrony
    - watch_in:
      - service: chrony

# rabbitmq-server
rabbitmq-server:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true

rabbitmqctl add_user openstack {{ salt['pillar.get']('RABBIT_PASS') }}:
  cmd.run:
    - require:
      - pkg: rabbitmq-server
    - onchanges:
      - service: rabbitmq-server
    - onchanges_in:
      - cmd: rabbitmqctl set_permissions openstack ".*" ".*" ".*"

rabbitmqctl set_permissions openstack ".*" ".*" ".*":
  cmd.run:
    - require:
      - cmd: rabbitmqctl add_user openstack {{ salt['pillar.get']('RABBIT_PASS') }}
    - onchanges:
      - cmd: rabbitmqctl add_user openstack {{ salt['pillar.get']('RABBIT_PASS') }}

# memcached
python-memcached:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

memcached:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - require:
      - file: /etc/sysconfig/memcached
    - watch:
      - file: /etc/sysconfig/memcached

/etc/sysconfig/memcached:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.sysconfig.memcached.template
    - template: jinja
    - require:
      - pkg: memcached
    - watch_in:
      - service: memcached

# keystone section
salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_keystone_db.sh.jinja:
  cmd.script:
    - template: jinja
    - onchanges:
      - service: mariadb-server

openstack-keystone:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

httpd:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/httpd/conf/httpd.conf
    - watch:
      - file: /etc/httpd/conf/httpd.conf

mod_wsgi:
  pkg.installed:
    - aggregate: true

/etc/httpd/conf/httpd.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.httpd.conf.httpd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: httpd
    - watch_in:
      - service: httpd

/etc/httpd/conf.d/wsgi-keystone.conf:
  file.symlink:
    - target: /usr/share/keystone/wsgi-keystone.conf
    - require:
      - pkg: httpd
      - pkg: mod_wsgi
    - watch_in:
      - service: httpd

/etc/keystone/keystone.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.keystone.keystone.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('KEYSTONE_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-keystone

populate keystone db:
  cmd.run:
    - name: su -s /bin/sh -c "keystone-manage db_sync" {{ salt['pillar.get']('KEYSTONE_USER') }}
    - onchanges:
      - file: /etc/keystone/keystone.conf

fernet setup:
  cmd.run:
    - name: keystone-manage fernet_setup --keystone-user {{ salt['pillar.get']('KEYSTONE_USER') }} --keystone-group {{ salt['pillar.get']('KEYSTONE_GROUP') }}
    - require:
      - cmd: populate keystone db
    - onchanges:
      - cmd: populate keystone db

fernet credential_setup:
  cmd.run:
    - name: keystone-manage credential_setup --keystone-user {{ salt['pillar.get']('KEYSTONE_USER') }} --keystone-group {{ salt['pillar.get']('KEYSTONE_GROUP') }}
    - require:
      - cmd: fernet setup
    - onchanges:
      - cmd: fernet setup

keystone bootstrap:
  cmd.run:
    - name: keystone-manage bootstrap --bootstrap-password {{ salt['pillar.get']('ADMIN_PASS') }} --bootstrap-admin-url http://{{ salt['pillar.get']('dnsname_controller') }}:35357/v3/ --bootstrap-internal-url http://{{ salt['pillar.get']('dnsname_controller') }}:5000/v3/ --bootstrap-public-url http://{{ salt['pillar.get']('dnsname_controller') }}:5000/v3/ --bootstrap-region-id RegionOne
    - require:
      - cmd: fernet credential_setup
    - onchanges:
      - cmd: fernet credential_setup

/root/admin-rc:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/root.admin-rc.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0700
  cmd.run:
    - require:
      - file: /root/admin-rc
    - onchanges:
      - file: /root/admin-rc

/root/demo-rc:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/root.demo-rc.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0700
    - require:
      - cmd: create domain, projects, users and roles

openstack token issue:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/openstack_token_issue.sh.jinja
    - template: jinja
    - require:
      - file: /root/admin-rc
    - onchanges:
      - file: /root/admin-rc

create domain, projects, users and roles:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/create_domain_projects_users_roles.sh.jinja
    - template: jinja
    - require:
      - file: /root/admin-rc
    - onchanges:
      - file: /root/admin-rc

create glance:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/create_glance.sh.jinja
    - template: jinja
    - require:
      - cmd: create domain, projects, users and roles
    - onchanges:
      - cmd: create domain, projects, users and roles

# glance packages
openstack-glance:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

/etc/glance/glance-api.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.glance.glance-api.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('GLANCE_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-glance

/etc/glance/glance-registry.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.glance.glance-registry.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('GLANCE_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-glance

populate glance db:
  cmd.run:
    # exit 0 as workaround for some deprecation messages (allowed here as mentioned in openstack install manual)
    - name: su -s /bin/sh -c "glance-manage db_sync; exit 0" {{ salt['pillar.get']('GLANCE_USER') }}
    - require:
      - file: /etc/glance/glance-api.conf
      - file: /etc/glance/glance-registry.conf
      - service: httpd
    - onchanges:
      - file: /etc/glance/glance-api.conf
      - file: /etc/glance/glance-registry.conf

openstack-glance-api:
  service.running:
    - enable: true
    - reload: true
    - require:
      - cmd: populate glance db

openstack-glance-registry:
  service.running:
    - enable: true
    - reload: true
    - require:
      - cmd: populate glance db

# nova section
salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_nova_db.sh.jinja:
  cmd.script:
    - template: jinja
    - onchanges:
      - service: mariadb-server

create nova user:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/create_nova_user.sh.jinja
    - template: jinja
    - require:
      - file: /root/admin-rc
    - onchanges:
      - file: /root/admin-rc

openstack-nova-api:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/nova/nova.conf
      - cmd: populate nova_api db
      - cmd: populate nova db
    - watch:
      - file: /etc/nova/nova.conf

openstack-nova-conductor:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/nova/nova.conf
      - cmd: populate nova_api db
      - cmd: populate nova db
    - watch:
      - file: /etc/nova/nova.conf

openstack-nova-console:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

openstack-nova-novncproxy:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/nova/nova.conf
      - cmd: populate nova_api db
      - cmd: populate nova db
    - watch:
      - file: /etc/nova/nova.conf

openstack-nova-scheduler:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/nova/nova.conf
      - cmd: populate nova_api db
      - cmd: populate nova db
    - watch:
      - file: /etc/nova/nova.conf

openstack-nova-placement-api:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

openstack-nova-consoleauth:
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/nova/nova.conf
      - cmd: populate nova_api db
      - cmd: populate nova db
    - watch:
      - file: /etc/nova/nova.conf

/etc/nova/nova.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.nova.nova.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NOVA_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-nova-api

/etc/httpd/conf.d/00-nova-placement-api.conf:
  file.append:
    - sources:
      - salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.httpd.conf.d.00-nova-placement-api.conf.append
    - require:
      - pkg: openstack-nova-placement-api
      - pkg: httpd
    - watch_in:
      - service: httpd

populate nova_api db:
  cmd.run:
    # exit 0 as workaround for some deprecation messages (allowed here as mentioned in openstack install manual)
    - name: su -s /bin/sh -c "nova-manage api_db sync; exit 0" {{ salt['pillar.get']('NOVA_USER') }}
    - require:
      - file: /etc/nova/nova.conf
      - service: httpd
    - onchanges:
      - file: /etc/nova/nova.conf

register cell0 database:
  cmd.run:
    - name: su -s /bin/sh -c "nova-manage cell_v2 map_cell0" {{ salt['pillar.get']('NOVA_USER') }}
    - require:
      - cmd: populate nova_api db
      - service: httpd
    - onchanges:
      - cmd: populate nova_api db

create cell1 database:
  cmd.run:
    - name: su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1" {{ salt['pillar.get']('NOVA_USER') }}
    - require:
      - cmd: register cell0 database
      - service: httpd
    - onchanges:
      - cmd: register cell0 database

populate nova db:
  cmd.run:
    # exit 0 as workaround for some deprecation messages (allowed here as mentioned in openstack install manual)
    - name: su -s /bin/sh -c "nova-manage db sync; exit 0" {{ salt['pillar.get']('NOVA_USER') }}
    - require:
      - cmd: create cell1 database
      - service: httpd
    - onchanges:
      - cmd: create cell1 database

# neutron section
salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_neutron_db.sh.jinja:
  cmd.script:
    - template: jinja
    - onchanges:
      - service: mariadb-server

create neutron:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/create_neutron.sh.jinja
    - template: jinja
    - require:
      - cmd: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_neutron_db.sh.jinja
    - onchanges:
      - cmd: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_neutron_db.sh.jinja

{% for neutron_pkg in ['openstack-neutron','openstack-neutron-ml2','openstack-neutron-linuxbridge','ebtables'] %}
{{ neutron_pkg }}:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
{% endfor %}

/etc/neutron/neutron.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.neutron.neutron.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NEUTRON_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-neutron

/etc/neutron/plugins/ml2/ml2_conf.ini:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.neutron.plugins.ml2.ml2_conf.ini.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NEUTRON_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-neutron

/etc/neutron/plugins/ml2/linuxbridge_agent.ini:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.neutron.plugins.ml2.linuxbridge_agent.ini.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NEUTRON_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-neutron

/etc/neutron/l3_agent.ini:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.neutron.l3_agent.ini.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NEUTRON_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-neutron

/etc/neutron/dhcp_agent.ini:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.neutron.dhcp_agent.ini.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NEUTRON_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-neutron

/etc/neutron/metadata_agent.ini:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.neutron.metadata_agent.ini.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NEUTRON_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-neutron

/etc/neutron/plugin.ini:
  file.symlink:
    - target: /etc/neutron/plugins/ml2/ml2_conf.ini
    - require:
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini

populate neutron db:
  cmd.run:
    - name: su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" {{ salt['pillar.get']('NEUTRON_USER') }}
    - onchanges:
      - cmd: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_neutron_db.sh.jinja

{% for neutron_service in ['neutron-server','neutron-linuxbridge-agent','neutron-dhcp-agent','neutron-metadata-agent','neutron-l3-agent'] %}
{{ neutron_service }}:
  service.running:
    - enable: true
    - reload: true
    - require:
      - cmd: populate neutron db
{% endfor %}

# dashboard section
openstack-dashboard:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

/etc/openstack-dashboard/local_settings:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.openstack-dashboard.local_settings.jinja
    - template: jinja
    - user: root
    - group: apache
    - mode: 0640
    - require:
      - pkg: openstack-neutron
    - watch_in:
      - service: httpd
      - service: memcached

# cinder section
salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_cinder_db.sh.jinja:
  cmd.script:
    - template: jinja
    - onchanges:
      - service: mariadb-server

create cinder:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/create_cinder.sh.jinja
    - template: jinja
    - require:
      - cmd: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_cinder_db.sh.jinja
    - onchanges:
      - cmd: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/add_cinder_db.sh.jinja

openstack-cinder:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike

/etc/cinder/cinder.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.cinder.cinder.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('CINDER_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-cinder

populate cinder db:
  cmd.run:
    - name: su -s /bin/sh -c "cinder-manage db sync" {{ salt['pillar.get']('CINDER_USER') }}
    - onchanges:
      - file: /etc/cinder/cinder.conf

{% for cinder_service in ['openstack-cinder-api','openstack-cinder-scheduler'] %}
{{ cinder_service }}:
  service.running:
    - enable: true
    - reload: true
    - require:
      - cmd: populate cinder db
{% endfor %}

# swift section
openstack-swift-proxy:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - pkg: openstack-swift-proxy
      - file: /etc/swift/proxy-server.conf
    - watch_in:
      - service: memcached

/etc/swift/proxy-server.conf:
  file.managed:
    - source: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/etc.swift.proxy-server.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-swift-proxy

create swift:
  cmd.script:
    - name: salt://{{ salt['pillar.get']('SALT_DIR') }}/files/create_swift.sh.jinja
    - template: jinja
    - require:
      - pkg: openstack-swift-proxy
    - onchanges:
      - pkg: openstack-swift-proxy

# account ring
swift-ring-builder account.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: create swift
    - onchanges:
      - cmd: create swift

swift-ring-builder account.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6202 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder account.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1
    - onchanges:
      - cmd: swift-ring-builder account.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1

swift-ring-builder account.builder rebalance:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder account.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6202 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100
    - onchanges:
      - cmd: swift-ring-builder account.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6202 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100

# container ring
swift-ring-builder container.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder account.builder rebalance
    - onchanges:
      - cmd: swift-ring-builder account.builder rebalance

swift-ring-builder container.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6201 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder container.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1
    - onchanges:
      - cmd: swift-ring-builder container.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1

swift-ring-builder container.builder rebalance:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder container.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6201 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100
    - onchanges:
      - cmd: swift-ring-builder container.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6201 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100

# object ring
swift-ring-builder object.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder container.builder rebalance
    - onchanges:
      - cmd: swift-ring-builder container.builder rebalance

swift-ring-builder object.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6200 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder object.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1
    - onchanges:
      - cmd: swift-ring-builder object.builder create 10 {{ salt['pillar.get']('swift:number_of_replica') }} 1

swift-ring-builder object.builder rebalance:
  cmd.run:
    - cwd: /etc/swift
    - require:
      - cmd: swift-ring-builder object.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6200 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100
    - onchanges:
      - cmd: swift-ring-builder object.builder add --region 1 --zone 1 --ip {{ salt['pillar.get']('mgmt_ip4_object1') }} --port 6200 --device {{ salt['pillar.get']('swift:object_storage') }} --weight 100

