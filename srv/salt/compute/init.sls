# /etc/hosts
/etc/hosts:
  file.managed:
    - source: salt://compute/files/etc.hosts.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

centos-release-openstack-pike:
  pkg.installed

openstack-nova-compute:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - require:
      - file: /etc/nova/nova.conf
    - watch:
      - file: /etc/nova/nova.conf

libvirtd:
  service.running:
    - enable: true
    - require:
      - file: /etc/nova/nova.conf
    - watch:
      - file: /etc/nova/nova.conf

/etc/nova/nova.conf:
  file.managed:
    - source: salt://compute/files/etc.nova.nova.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('NOVA_USER') }}
    - require:
      - pkg: openstack-nova-compute
























