---
title: 'Ansible: The Bronze Bullet, Part 1: The Ansible Pseudo-Language'
published: false
tags: [ansible_bronze_bullet, ansible]
---

- complexity outsourced to YAML, Jinja, modules
- no separation between "force this state" and "do this action"
  - RDS module has many commands
- register vs fact vs variable?
  - facts and variables share the same namespace?
  - "Inside a template you automatically have access to all of the variables
    that are in scope for a host." What's scope?
- no generator expressions in Jinja
- hosts are the only first-class object
- impossible?
  - create an rds subnet group: how do you get eh IDs?
- fact vs variable
  - setting a variable is a non-trivial task
- the documentation lacks reference
  - what will the register result of this task be?
    "Returns information about the specified cache cluster."
- key=value syntax
  - pacman uses "name: package,package", and "name: [package, package]" doesn't work
- uses local /etc for some reason
- "Examples (which typically contain colons, quotes, etc.) are difficult to
  format with YAML, so these must be written in plain text in an EXAMPLES string
  within the module like this:" -- False! Use >
- Invented a new set notation
- rds "command: create" *is* idempotent. ec2 "state: present" *isn't*
- inconsistent:
  - rds "subnet" for subnet group
  - elasticache "cache_subnet_groups" for subnet groups
- "doc fix": docs.ansible.com is based off of the devel branch?

    cache_subnet_group	yes	None	The subnet group name to associate with. Only use if inside a vpc. Required if inside a vpc (added in Ansible 1.7)

  Uses git submodules for ansible modules, 
- If core-modules is a submodule that tracks devel, the released (stable)
  version on PyPI has an arbitrary devel snapshot in it
- Can't tell when a string will be run through Jinja:
  - environment:
  - vars?
  - module args
- AWS modules have a wait: param sometimes, not others
- ansible is not a programming language: 
    - http://comments.gmane.org/gmane.comp.sysutils.ansible/1406
    - https://groups.google.com/d/msg/ansible-project/tisr0c8eovc/SVCTAb5SP5gJ
