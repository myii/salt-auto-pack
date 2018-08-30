{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set uder_version_file = base_cfg.build_salt_dir ~ '/salt/_version.py' %}

{% set specific_user = pillar.get('specific_name_user', 'saltstack') %}
{% set build_local_minion = grains.get('id') %}


{% if base_cfg.build_specific_tag == false %}

## extract any chars and numbers for version override - 'nb201706151406291234'
{% set dsig_list = base_cfg.build_dsig|list %}

{% if dsig_list|length >= 3 %}
{% set dsig_chars = dsig_list[0] ~ dsig_list[1] %}
{% set dsig_numbs = dsig_list[2:]|join('') %}
{% else %}
{# cause an error #}
{% endif %}

{% set have_tag_from_pypi = false %}

{% else %}

{% set have_tag_from_pypi_dict = salt.cmd.run("salt " ~ build_local_minion ~ " file.file_exists " ~ base_cfg.build_salt_pypi_dir ~ "/salt-" ~ base_cfg.build_version_full_dotted ~ ".tar.gz -l quiet --out=json")  | load_json %}
{% if have_tag_from_pypi_dict[build_local_minion] == True %}  
{% set have_tag_from_pypi = true %}
{% else %}
{% set have_tag_from_pypi = false %}
{% endif %}

{% endif %}


build_pkgs:
  pkg.installed:
   - pkgs:
     - git


{{base_cfg.build_runas}}:
  user.present:
    - groups:
      - adm
    - require:
      - pkg: build_pkgs


build_create_salt_code_dir:
  file.directory:
    - name: {{base_cfg.build_salt_dir}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True


## {# - name: https://github.com/{{specific_user}}/salt.git #}
##    - name: https://github.com/saltstack/salt.git
retrieve_desired_salt:
  git.latest:
    - name: https://github.com/{{specific_user}}/salt.git
    - target: {{base_cfg.build_salt_dir}}
    - rev: {{base_cfg.branch_checkout_tag}}
    - user: {{base_cfg.build_runas}}
    - force_reset: True
    - force_clone: True


build_remove_version_override:
  file.absent:
    - name: {{uder_version_file}}


## {#{% if base_cfg.build_specific_tag == false and specific_user == 'saltstack' %}#}

{% if base_cfg.build_specific_tag == false %}

build_write_version_override:
  file.append:
    - name: {{uder_version_file}}
    - text: |
        from salt.version import SaltStackVersion
        __saltstack_version__ = SaltStackVersion( {{base_cfg.build_year}}, {{base_cfg.build_major_ver}}, {{base_cfg.build_minor_ver}}, 0, '{{dsig_chars}}', {{dsig_numbs}}, 0, None )


build_write_version_override_rights:
  module.run:
    - name: file.chown
    - path: {{uder_version_file}}
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - require:
      - file: build_write_version_override

{% endif %}


{% if have_tag_from_pypi == false %}

build_salt_sdist:
  cmd.run:
    - name: /usr/bin/python setup.py sdist
    - runas: {{base_cfg.build_runas}}
    - cwd: {{base_cfg.build_salt_dir}}
    - reset_system_locale: False
{% if base_cfg.build_specific_tag == false %}
    - require:
      - module: build_write_version_override_rights
{% endif %}

{% else %}
ensure_dist:
  file.directory:
    - name: {{base_cfg.build_salt_dir}}/dist
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True


use_pypi_dist:
  cmd.run:
    - name:
        cp {{base_cfg.build_salt_pypi_dir}}/salt-{{base_cfg.build_version_full_dotted}}.tar.gz  {{base_cfg.build_salt_dir}}/dist/


cleanup_pypi_dist:
  file.absent:
    - name: {{base_cfg.build_salt_pypi_dir}}

{% endif %}


