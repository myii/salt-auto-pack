{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment high-lighting

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set build_py_ver = 'py3' %}
{% else %}
{% set build_py_ver = 'py2' %}
{% endif %}

{% set build_arch = grains.get('osarch') %}

## set platform
{% if grains.get('os_family') == 'Debian' -%}
{% set platform_pkg = 'apt' %}

{% if grains.get('os') == 'Ubuntu' -%}
{% set platform = grains.get('os')|lower -%}
{% set os_version = grains.get('osrelease') %}
{% set tgt_build_release = platform ~ os_version.replace('.', '') %}
{% else %}
{% set platform = grains.get('os_family')|lower -%}
{% set os_version = grains.get('osmajorrelease') %}
{% set tgt_build_release = platform ~ grains.get('osmajorrelease') %}
{% endif %}

{% elif grains.get('os_family') == 'RedHat' -%}
{% set platform_pkg = 'yum' %}

{% if grains.get('os') == 'Amazon' -%}
{% set platform = grains.get('os')|lower -%}
{% if build_py3 %}
## only build Amazon Linux 2 for Py3, Amazon Linux 1 for Py2
{% set os_version = '2' %}
{% set tgt_build_release = 'amzn' ~ os_version %}
{% else %}
{% set os_version = 'latest' %}
{% set tgt_build_release = 'amzn' %}
{% endif %}
{% else %}
{% set platform = grains.get('os_family')|lower -%}
{% set tgt_build_release = 'rhel' ~ grains.get('osmajorrelease') %}
{% set os_version = grains.get('osmajorrelease') %}
{% endif %}

{% else %}
{% set platform_pkg = 'Unsupported-platform-packager' -%}
{% set platform = 'Unsupported-platform' -%}
{% set tgt_build_release = 'Unsupported-platform' -%}
{% endif %}

{% set minion_platform = pillar.get('build_release', tgt_build_release) %}
{% set specific_user = pillar.get('specific_name_user', 'saltstack') %}
{% set build_dest = pillar.get('build_dest') %}
{% set platform_name = platform|lower %}
{% set nb_srcdir = build_dest ~ '/' ~ build_py_ver ~ '/' ~ minion_platform ~ '/' ~ build_arch %}


mkdir_deps_packages:
  file.directory:
    - name: {{nb_srcdir}}
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - dir_mode: 775
    - file_mode: 644
    - makedirs: True
    - recurse:
        - user
        - group
        - mode


ensure_saltstack_gpg_pub_key:
  file.managed:
    - name: {{nb_srcdir}}/SALTSTACK-GPG-KEY.pub
    - source: salt://{{slspath}}/SALTSTACK-GPG-KEY.pub
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - mode: 644
    - force: True
    - makedirs: True
    - preserve: True

{%- if grains.get('os_family') == 'Debian' %}
ensure_saltstack_gpg_pub_keyring:
  file.managed:
    - name: {{nb_srcdir}}/salt-archive-keyring.gpg
    - source: salt://{{slspath}}/salt-archive-keyring.gpg
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - mode: 644
    - force: True
    - makedirs: True
    - preserve: True
{%- endif %}


