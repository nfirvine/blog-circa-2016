---
title: 'Ansible: The Bronze Bullet, Part 1: The Ansible Pseudo-Language'
published: true
layout: post
tags: [ansible_bronze_bullet, ansible]
---

> We didn't want to create a new language like Chef, so we frankensteined together some hot web tech.

<cite>-- Ansible designers (not a real quote, naturally)</cite>

Ansible playbooks are written in YAML. You've probably seen YAML before. It's a pretty straightforward data serialization format, very similar to JSON (in fact, it's a superset), but with sane additions like comments and not having to quote string keys. It's much much lighter than XML, but can represent a lot of the same things. Ruby on Rails is really hot on it. IMHO, it's better than JSON in every way I can think of.

The choice of using a serialization format to represent what is essentially a list of instructions is an odd one. That sounds like a *script* to me. Having your code look like it's declarative is deceptive when it's definitely going to get executed sequentially, like a script. We'd all love to think of our systems as sets of declarative configuration statements, but that's simply not realistic: entropy creeps into that careful order, and time rots all bits. And as your systems' states drift and that diff gets longer, it's harder to pull it back on course.

Ansible makes that age old mistake of using the extension of its data format. A playbook is not just any old YAML, it's got a specific structure that looks sort of like this:

{% highlight yaml %}{% raw %}
- name: #< the map that "name" goes in is a play
  hosts: <host list>
  tasks: <task list>
{% endraw %}{% endhighlight %}

And is named `<something>.yml`. When you get into roles, you'll also see `{tasks,handlers,vars,meta}/main.yml`, and these each expect different data structures. But damned if you can tell them apart in a text editor by just the filename.

There's a problem with treating your script as declaritive: there's no variables or looping structures or if statements. Ansible fixes this by (along with `with_` loop construct, which we'll get to later) adding another third-party language on top: Jinja. But it's not declarative YAML inside Jinja templates, the way Jinja works with HTML; it's the other way around: Jinja templates inside YAML strings.

Jinja is a semi-respectable language on its own, sure: it's easy enough to write, kind of like Python. Ish. Anyway, its data model maps to Python. Kind of. What's not easy is writing Jinja templates inside YAML strings. You see, most of the time, if you're writing a key-value pair for a map in YAML, and the value is a string, you can just write this, without using quotes:

{% highlight yaml %}{% raw %}
key: I am a value
{% endraw %}{% endhighlight %}

or in equivalent JSON:

{% highlight json %}{% raw %}
{"key": "I am a value"}
{% endraw %}{% endhighlight %}

But there's what the Ansible docs call a ["YAML gotcha"](http://docs.ansible.com/YAMLSyntax.html#gotchas): When you're writing templated values (like variables), Jinja uses syntax like `{% raw %}{{var}}{% endraw %}`, and this collides with YAML's inline map notation. Instead of this:

{% highlight yaml %}{% raw %}
target_host: {{hostname}}
{% endraw %}{% endhighlight %}

turning into this:

{% highlight json %}{% raw %}
{"target_host": "nfi.io"}
{% endraw %}{% endhighlight %}

you get a syntax error because it looks to YAML like you wrote some broken maps with missing values. The solution is to put explicit quotes around your templated strings, and only around the rest of your strings if you feel like it or if you might template them someday.

I would argue that this is not a "YAML gotcha" but an Ansible gotcha: Ansible chose as its playbook language to bodge together two languages that naturally collided in their most basic usage.

And let's keep in mind, Jinja is not a programming language.

Two more layers of bodge
========================

When `ansible-playbook` executes a task, it pushes the task's module code to the remote side, then executes it, calling it with the arguments specified. Core Ansible modules are all Python, and they get passed the arguments as a JSON blob and decoded into Python data structures. To summarize, if we've got a templated argument to a module, the flow is:

- parse playbook into Python data structures from YAML
- for each task, parse certain atoms with Jinja and sub them back into the Python task's arguments
- serialize the arguments structure into JSON
- deserialize them from JSON into Python on the remote side

I dunno about you, but that's a lot of transformation. It makes me think things like "Can I trust a JSON roundtrip to handle this very big number?" and "I guess that list is a string now. :("

It makes you wonder why just stick with JSON? Well, JSON's fiddly to write and doesn't look so clean. Why not stick with YAML? YAML isn't included with Python (like JSON is), which breaks the "agentless" promise.

Check this out; one more language (I call it "CGI-style"): `key=value key=value`. But this only works for module arguments. Let's see [how it's used in the docs](http://docs.ansible.com/ec2_module.html):

{% highlight yaml %}{% raw %}
- name: Add new instance to host group
  add_host: hostname={{ item.public_ip }} groupname=launched
{% endraw %}{% endhighlight %}

Which is equivalent to:

{% highlight yaml %}{% raw %}
- name:
  add_host:
    hostname: '{{item.public_ip}}'
    groupname: launched
{% endraw %}{% endhighlight %}

Did you count how many languages that is in one line in the example? 3: YAML, Jinja, and CGI-style. That means three different sets of things like quoting, typing, and escaping. Can Jinja handle unicode curly quotes? I don't know, and I certainly don't want to have to figure it out three times. 

YAML has a perfectly good one-line map syntax (`add_host: {hostname: '{{item.public_ip}}', groupname: launched}`), so I don't know why they felt they had to invent this. Maybe it was created before playbooks were a thing, but then why keep switching between real YAML maps and fake CGI ones in the docs?

(In fact, [there are plenty more ways to specify the (action, args) pair](https://github.com/ansible/ansible/blob/devel/lib/ansible/parsing/mod_args.py#L44-L87) that I won't get into. Orthogonality? What's that?)

Looping and generating
======================

Looping: it's probably the second programming construct you learn after printing "Hello world!". Python adds generators which allow you to construct lists and maps in expressions instead of looping statement. So suffice it to say they're well understood.

And yet the Ansible language designers, already having 5 sub-languages at their disposal, decide to roll their own!  YAML, being a data representation language, doesn't come with loops. Jinja has loops, but using them would mean that playbooks would have to be YAML in Jinja, not Jinja in YAML (which isn't a totally terrible idea except you want some of it to be evaluated at runtime).

A task can take a `with_items` argument to specify that you want to do this task for each of the items in a given list; you just use `item` to refer to the current item. For no discernable reason, `with_items` gives you a warning if pass it a template -- you're only supposed to give the *name* of a list, not a list itself (despite the fact that [the docs clearly have a lot of templated `with_items` examples](https://github.com/ansible/ansible/blob/devel/docsite/rst/playbooks_loops.rst#using-register-with-a-loop).

Even so, let's just ignore that warning for a second. Let's say you got a dictionary from the last command that maps filenames to modes, and you want to print them. You'd think you could do this:

{% highlight yaml %}{% raw %}
shell: echo {{item[0]}}'s mode is {{item[1]}}
with_items: '{{ [[filename, mode] for filename, mode in filemodes.itervalues()] }}.
{% endraw %}{% endhighlight %}

Nope. Jinja2 isn't real Python, and doesn't support generators. Ansible works around this by introducing a *family* of underspecified looping constructs that map a variety of inputs types to a variety of output types. `with_together: [list1, list2]` is equivalent to `with_items: zip(list1, list2)`, if that syntax worked in Jinja, and it's shorter and certainly clearer. Reinventing the wheel, making it subtly different, and then calling it a "round mobility blob" is pretty frustrating.

Patterns: yet another goofy Ansible invention
=============================================

In the `hosts` argument to a play (among other places), you can specify a pattern to match a set of hosts. The pattern syntax supports wildcards, regexs, and some set operations. The set operators are:

- `:` -- or; union
- `:&` -- and; intersection
- `:!` -- difference

Where the hell did they get those? I dunno. Python, for example, has some perfectly reasonable set operators:

- `|` -- union
- `&` -- intersection
- `-` -- difference

Notice how they're analogous to their bitwise operator counterparts? Isn't that handy? One less thing to remember.

Wildcard patterns can look like this: `192.168.1.*` (that's from the docs). You'd think that was doing something more clever than a fnmatch and match the IP range 192.168.1.[0-255], right? Nope. It's just fnmatch, so you also get `192.168.1.foo.bar.com`.

Closing
=======

The Ansible playbook language is a great example of an undesign: something that just got features bolted onto it as it grew without a whole lot of direction. (At least, there's no direction that I can discern.) 

Michael DeHaan, the creator of Ansible, wrote ["we really aren't trying to create a programming language"](https://groups.google.com/d/msg/ansible-project/tisr0c8eovc/SVCTAb5SP5gJ). Well, no this isn't a *general purpose* programming language, but it's certainly a programming language. You're describing a list of steps you want a computer system to perform; that's a programming language. When I'm looking at a new language, I've got only a few criteria which I use to judge it, I ask myself some questions.

- Does it reuse existing analogies and constructs from other well-known languages? Where it deviates, are the good reasons for doing so? Where it's the same, does it reuse their names and symbols where possible?
- Is its expressive power greater than competing tools and languages?
- If it encorporates existing tech, does it bitch about how that tech sucks?

The Ansible playbook language fails in all these regards. When I started learning and using Ansible, one of the big selling points was Python. But unless you're writing modules or plugins, you don't get the full expressive power of Python, you get the weird sort-of-Python that is Jinja.

I mean, we're really not doing much better than the pile of Bash scripts we had when we started using Ansible playbooks. What if we just wrote bash scripts that called out to the simple `ansible` command to do remote stuff? Then we'd get the power of the Ansible modules (more on that later) and the known weirdness of Bash scripting. Better the devil you know, right?
