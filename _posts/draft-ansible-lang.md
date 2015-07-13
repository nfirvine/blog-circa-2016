---
title: Ansible Part 1: The Ansible Pseudo-Language
published: false
tags: [ansible]
---

> We didn't want to create a new language like Chef, so we frankensteined together some hot web tech.

> -- <cite>Ansible designers (not a real quote, naturally)</cite>

Ansible playbooks are written in YAML. You've probably seen YAML before. It's pretty straightforward data serialization format, very similar to JSON (in fact, it's a superset), but with sane additions like comments and not having to quote string keys. It's much much lighter than XML, but can represent a lot of the same things. Ruby on Rails is really hot on it. IMHO, it's better than JSON in every way I can think of.

The choice of using a serialization format to represent what is essentially a list of instructions is an odd one. That sounds like a *script* to me. Having your code look like it's declarative is deceptive when it's definitely going to get executed sequentially, like a script. We'd all love to think of our systems as sets of declarative configuration statements, but that's simply not realistic: entropy creeps into that careful order, and time rots all bits. And as your systems' states drift and that diff gets longer, it's harder to pull it back on course.

Ansible makes that age old mistake of using the extension of its data format. A playbook is not just any old YAML, it's got a specific structure that looks sort of like this:

```yaml
- name: #< the map that "name" goes in is a play
  hosts: <host list>
  tasks: <task list>
```

And is named `<something>.yml`. When you get into roles, you'll also see `{tasks,handlers,vars,meta}/main.yml`, and these each expect different data structures. But damned if you can tell them apart in a text editor by just the filename.

There's a problem with treating your script as declaritive: there's no looping structures and no if statements. Ansible fixes this by adding another third-party language on top: Jinja. But it's not declarative YAML inside Jinja templates, the way Jinja works with HTML; it's the other way around: Jinja templates inside YAML strings 

Jinja is a semi-respectable language on its own, sure: it's easy enough to write, kind of like Python. Ish. Anyway, it's datamodel maps to Python. Kind of. What's not easy is writing Jinja templates inside YAML strings. You see, most of the time, if you're writing a key-value pair for a map in YAML, and the value is a string, you can just write this, without using quotes:

```yaml
key: I am a value
```

or in equivalent JSON:

```json
{"key": "I am a value"}
```

But there's what the Ansible docs call a ["YAML gotcha"](http://docs.ansible.com/YAMLSyntax.html#gotchas): When you're writing templated values (like variables), Jinja uses syntax like `{{var}}`, and this collides with YAML's inline map notation. Instead of this

```yaml
target_host: {{hostname}}
```

turning into this:

```json
{"target_host": "nfi.io"}
```

you get a syntax error because it looks to YAML like you wrote some broken maps with missing values. The solution is to put explicit quotes around your templated strings, and only around the rest of your strings if you feel like it or if you might template them someday.

I would argue that this is not a "YAML gotcha" but an Ansible gotcha: Ansible chose as its playbook language to bodge together two languages that naturally collided in their most basic usage.

Two more layers of bodge
------------------------

When `ansible-playbook` executes a task, it pushes the task's module code to the remote side, then executes it, calling it with the arguments specified. Core Ansible modules are all Python, and they get passed the arguments as a JSON blob and decoded into Python data structures. To summarize, if we've got a templated argument to a module, it goes:

<!-- TODO: fact-check -->

- parse playbook into Python data structures from YAML (some of them probably being Python classes)
- for each task, parse certain atoms with Jinja and sub them back into Python task's arguments
- serialize the arguments structure into JSON
- deserialize them from JSON into Python on the remote side

I dunno about you, but that's a lot of transformation. It makes me think things like "Can I trust a JSON roundtrip to handle this very big number?" and "I guess that list is a string now. :("

It makes you wonder why just stick with JSON? Well, JSON's fiddly to write and doesn't look so clean. Why not stick with YAML? YAML isn't included with Python (like JSON is), which breaks the "agentless" promise.

More than one way to do things (badly)
======================================

- = vs native YAML args 

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
