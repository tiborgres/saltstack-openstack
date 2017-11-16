# /etc/hosts
/etc/hosts:
  file.managed:
    - source: salt://object/files/etc.hosts.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

centos-release-openstack-pike:
  pkg.installed

{% for basic_pkg in ['xfsprogs','rsync'] %}
{{ basic_pkg }}:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
{% endfor %}

mkfs.xfs /dev/{{ salt['pillar.get']('object_storage') }}:
  cmd.run:
    - require:
      - pkg: xfsprogs
    - onchanges:
      - pkg: xfsprogs

{{ salt['pillar.get']('dir_structure') }}/{{ salt['pillar.get']('object_storage') }}:
  mount.mounted:
    - device: /dev/{{ salt['pillar.get']('object_storage') }}
    - fstype: xfs
    - mkmnt: true
    - opts: noatime,nodiratime,nobarrier,logbufs=8
    - dump: 0
    - pass_num: 2
    - persist: true
    - require:
      - cmd: mkfs.xfs /dev/{{ salt['pillar.get']('object_storage') }}
  file.directory:
    - user: {{ salt['pillar.get']('SWIFT_USER') }}
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - require:
      - mount: {{ salt['pillar.get']('dir_structure') }}/{{ salt['pillar.get']('object_storage') }}

rsyncd:
  service.running:
    - enable: true
    - reload: true
    - require:
      - pkg: rsync
      - file: /etc/rsyncd.conf
    - watch:
      - file: /etc/rsyncd.conf

/etc/rsyncd.conf:
  file.managed:
    - source: salt://object/files/etc.rsyncd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: rsync

/etc/swift/swift.conf:
  file.managed:
    - source: salt://object/files/etc.swift.swift.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0640

/etc/swift/account-server.conf:
  file.managed:
    - source: salt://object/files/etc.swift.account-server.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-swift-account

/etc/swift/container-server.conf:
  file.managed:
    - source: salt://object/files/etc.swift.container-server.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-swift-container

/etc/swift/object-server.conf:
  file.managed:
    - source: salt://object/files/etc.swift.object-server.conf.jinja
    - template: jinja
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0640
    - require:
      - pkg: openstack-swift-object

/var/cache/swift:
  file.directory:
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0755

/etc/swift:
  file.directory:
    - user: root
    - group: {{ salt['pillar.get']('SWIFT_GROUP') }}
    - mode: 0755
    - require:
      - file: /etc/swift/swift.conf
      - file: /etc/swift/account-server.conf
      - file: /etc/swift/container-server.conf
      - file: /etc/swift/object-server.conf

{% for swift_pkg in ['openstack-swift-account','openstack-swift-container','openstack-swift-object'] %}
{{ swift_pkg }}:
  pkg.installed:
    - aggregate: true
    - require:
      - pkg: centos-release-openstack-pike
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/swift
{% endfor %}

{% for swift_service in ['openstack-swift-account-auditor','openstack-swift-account-reaper','openstack-swift-account-replicator','openstack-swift-container-auditor','openstack-swift-container-replicator','openstack-swift-container-updater','openstack-swift-object-auditor','openstack-swift-object-replicator','openstack-swift-object-updater'] %}
{{ swift_service }}:
  service.running:
    - enable: true
    - reload: true
    - require:
      - file: /etc/swift
{% endfor %}




















