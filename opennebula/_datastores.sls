#!jinja|yaml

{% set datamap = salt['formhelper.get_defaults']('opennebula', saltenv, ['yaml'])['yaml'] %}

#include:
#  - opennebula._user_oneadmin

{% for d in datamap.datastores|default([]) if d.type in [ 'nfs', 'nfs4', 'dir' ] %}
one_datastore_{{ d.name }}:
  file:
    - directory
    - name: {{ d.name }}
    - mode: {{ d.dirmode|default('755') }}
    - user: {{ d.user|default('9869') }}
    - group: {{ d.group|default('9869') }}
    - makedirs: {{ d.makedirs|default(True) }}
  {% if d.get('source', False) and d.get('type', False) %}
  mount:
    - mounted
    - name: {{ d.name }}
    - device: {{ d.source }}
    - fstype: {{ d.type }}
    - opts: {{ d.opts|default('auto') }}
    - persist: {{ d.persist|default(True) }}
  {% endif %}
{% endfor %}
{% for d in datamap.datastores|default([]) if d.type in [ 'symlink' ] %}
#one_datastore_{{ d.name }}:
#  file:
#    - symlink
#    - name: {{ d.name }}
#    - target: {{ d.target }}
#    - user: {{ d.user|default('9869') }}
#    - group: {{ d.group|default('9869') }}
#    - makedirs: {{ d.makedirs|default(True) }}
#fix for https://github.com/saltstack/salt/issues/47032
one_datastore_{{ d.name }}:
  cmd:
    - run
    - name: ln -s {{ d.target }} {{ d.name }}
    - unless: test -n "`find {{ d.name }} -type l`"
one_datastore_{{ d.name }}fix:
  cmd:
    - run
    - name: chown -h {{ d.user|default('9869') }}:{{ d.group|default('9869') }} {{ d.name }}
    - unless: test -n "`find {{ d.name }} -type l -user {{ d.user|default('9869') }} -group {{ d.group|default('9869') }}`"
    - require:
      - cmd: one_datastore_{{ d.name }}
{% endfor %}
