# /etc/hosts
/etc/hosts:
  file.managed:
    - source: salt://block/files/etc.hosts.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

centos-release-openstack-pike:
  pkg.installed

lvm2:
  pkg.installed:
    - aggregate: true

lvm2-lvmetad:
  service.running:
    - enable: true
    - reload: true
    - require:
      - pkg: lvm2

pvcreate /dev/{{ salt['pillar.get']('lvmdevice') }}:
  cmd.run:
    - require:
      - pkg: lvm2
    - onchanges:
      - service: lvm2-lvmetad

vgcreate {{ salt['pillar.get']('vgname') }} /dev/{{ salt['pillar.get']('lvmdevice') }}:
  cmd.run:
    - require:
      - pkg: lvm2
    - onchanges:
      - cmd: pvcreate /dev/{{ salt['pillar.get']('lvmdevice') }}

/etc/lvm/lvm.conf:
  file.managed:
    - source: salt://block/files/etc.lvm.lvm.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: lvm2

{% for cinder_pkg in ['openstack-cinder','targetcli','python-keystone'] %}
{{ cinder_pkg }}:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
{% endfor %}

/etc/cinder/cinder.conf:
  file.managed:
    - source: salt://block/files/etc.cinder.cinder.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('CINDER_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-cinder

{% for cinder in ['openstack-cinder-volume','target'] %}
{{ cinder }}:
  service.running:
    - enable: true
    - require:
      - pkg: openstack-cinder
      - pkg: targetcli
    - watch:
      - file: /etc/cinder/cinder.conf
{% endfor %}
