---
title: 'Ansible: Not the Silver Bullet You Were Looking For (Part 0)'
layout: post
date: 2015-07-13
tags: [ansible, ansible_bronze_bullet]
---
Ansible. Ansible Ansible Ansible. Everybody's all about Ansible these days. And it's good. It's pretty simple when compared to Salt and Chef and the rest. It uses some common and easy to learn tech like Python, YAML, and Jinja, so you don't have to learn a weird Ruby DSL; I already know Python and YAML pretty well. You can reuse your existing SSH infrastructure too.

But it's not without its flaws. In fact, I argue that if you're doing anything beyond the usual "I want to trigger a bunch of scripts to run on these hosts", Ansible's probably the wrong choice.

I worked with Ansible a long time ago for IT stuff like configuring servers, as well as a little deployment stuff. But it was always just used on the fringes to trigger some remote Python or Bash scripts. Recently, though, I got a chance to dive a little deeper. A client wanted to automated the complete creation of his web app in AWS. Seems like the type of thing Ansible would be great at.

The app in question has some pretty standard bits:

- A handful of Python web apps, reverse-proxied with Nginx
- RDS database
- Elasticache cache

Couldn't be simpler, right? Well, it ended up taking me several hundred lines of ansible with plenty of stupid hacks and shelling out. I'm using this as an opportunity to write a series on the problems I encountered.

And just to be clear, Ansible is not total garbage. It just feels like it's a quick hack that grew too quickly. At a previous job, we had plans to standardize on Ansible, but I'm glad we never got around to it.

What is Ansible supposed to be?
===============================

If I'm going to knock something, I like to clarify what I think that thing is: maybe it doesn't suck -- my mental model is just broken.

Ansible is an automation tool. At the top level, you write playbooks to ["describe a policy ..., or a set of steps"](http://docs.ansible.com/playbooks.html), where a playbook is a list plays, each of which is a series of tasks to be executed on a set of hosts. Tasks are almost always invocations of Ansible "modules" -- Python scripts that are deployed to the remote host and called with some arguments.

Ultimately, playbooks are a sort of "metascript", a script for triggering scripts. Bash as it stands has rather limited (read: non-exist) support for remote execution, but with a playbook, you can orchestrate a bunch of scripts to fire on certain hosts in series. Playbooks have a sort of implied zeroth play, which is to reach out to each host and fetch a huge chunk of its state.

["Playbooks are designed to be human-readable and are developed in a basic text language."](http://docs.ansible.com/playbooks.html) Ansible says it's simple, presumably to appeal to all of us who thought Chef was too foreign to comprehend. We're dealing with hard problems here, and making it simple is no small task. In Ansible, a lot of the complexity is in the modules, not the core.

Ansible has a first-class use case document claiming it has ["extensive AWS support"](http://www.ansible.com/aws), as well as [a detailed guide on using AWS modules](http://docs.ansible.com/guide_aws.html), so it's safe to say AWS should be well-supported.

Next time on Ansible: Not the Silver Bullet...
==============================================

I'm going to be talking about [the Ansible language, playbooks]({% post_url 2015-07-17-ansible-lang %}).
