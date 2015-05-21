---
layout: post
title: What to do with abandoned FOSS?
date: 2015-05-20
---

Trying to set up a new workstartion with the Solarized colour scheme in my terminal and vim. After an hour of banging my head against the wall, I've given in and just type random words into Google. I find [a helpful askubuntu post that notes that the format of the colors spec is outdated](http://askubuntu.com/questions/315230/solarized-theme-in-terminal-vim-on-xubuntu). The repo is useless.

Turns out the repo I was using is dead. Somebody reported this bug ages ago, and the maintainer never fixed it. It's a trivial amount of work really, probably a Vim one-liner.

I'm not really complaining that the guy didn't do the work; I'm complaining that he didn't bother to write that the repo is dead. I could do the work; I pretty much already have. But then I get to write a pull request that goes to /dev/null, so what's the point?

This repo is kind of a sub-repo of [the official Solarized repo](https://github.com/altercation/solarized) from the creator's website. (Not a real gitsubmodule; just a portion of the tree.) So I thought I'd report it to the upstream repo. Looks like Solarized is dead too: the last closed PR was in 2013, the last closed issue was April 2014, and there's [even a bug asking if the thing is dead](https://github.com/altercation/solarized/issues/299).

Does this have any greater meaning? With free-as-in-beer entire OSes being handed out like candy, maybe we've started taking FOSS for granted. But on the other hand, maybe github needs a way to flag a repo as deprecated and no longer supported. If you're going to take on the responsibility of hosting the canonical fork of a piece of software (even if it's just a colour palette), I think you have the responsibility to shut it down when you're done with it.
