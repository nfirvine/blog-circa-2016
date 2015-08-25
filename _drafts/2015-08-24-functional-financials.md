---
title: Functional Financials
layout: post
#date: 2015-08-24
tags: [idea]
---
I've been dealing with mortgages a lot lately, for the first time in my life. It got me thinking: what if, instead of your bank account being a list of transactions, it's a list of _functions_.

I've taken a few runs at rolling my own personal financial system, sometimes using spreadsheets (spreadsheets are just so archaic), sometimes using a real database, and sometimes using JSON or YAML blobs. I always lose interest eventually, but I think I keep coming back to it because of one fundamental question that doesn't get addressed in any existing software I can find: precisely how much money will I have at time `t` and am I breaking any rules (overdraft, etc.)? The "precisely" is important: I don't mean "okay, my annual income is $net after taxes, and I spend $rent + $food + ...; therefore, in 10 years, I will have ($net - $expenses) * 10 net worth if nothing changes"; I want to be able to figure out the exact amount of money I will have at any given time (under some assumptions).

The precision is not critical when you're dealing with small scales, but when you're talking hundreds of thousands like mortgages, it's really something to consider. Every day your money's sitting in an account not making interest might be hundreds of dollars or more. So let's consider a scenario where we want very high precision.

When you're paying back a loan or doing any money transfer over a period of time, you end up paying in chunks, discrete packets of money. This is because electonic money is modelled after physical things like cash and gold which are not inifinitely divisible (practically). Also, more precision costs more bits costs more overhead: in databases, in network packets, etc. But consider that what you're really doing is modelling some real function by discarding a bunch of precision so that the transactions only need to occur on some human-manageable time-scale (like weekly or monthly).

As an example, say we have the following loan:

- $1M principal
- 5% interest annually
- 25 year amortization
- yearly interest compounding



