---
layout: post
title: Clash Royale protocol dissection
date: 2016-03-28
---

I spent a little time trying to reverse engineer the match protocol for Clash Royale. I've been working on a realtime synchronous multiplayer title for mobile and thought it'd help to look at what others are doing. On my game, I had been working on the assumption that UDP to mobile was not good enough (a questionable assumption), that it wouldn't make it through corporate firewalls and such, so I wrote a proof of concept that used JSON over Websockets.

Turns out JSON over Websockets is pretty rough. Websockets are complicated, and their semantics are not quite like TCP or UDP. Even after I implemented the sim part of the game, the JSON choice was (not surprisingly) contributing significantly to CPU and memory usage. Next steps in the project included moving to a binary protocol.

That was fun. But I also wanted to see what other mobile games do for realtime synchronous gameplay, and challenge the UDP assumption.

Here, I'm only looking at the realtime protocol used. There's a load of HTTP(S) traffic before the match is started, presumably to do with match making and locating a server. However, I didn't look too closely at it. (Maybe later.)

I hadn't done much binary protocol analysis before (mostly HTTP(S) previously), and I thought I'd use the opportunity to learn Wireshark a little better. Wireshark's got a decent LUA plugin API that you can use to write protocol dissectors, the software that shows you what parts of a packet are what.

Basically the way it works is that you:

- create a Proto, a protocol
- add ProtoFields, fields for each packet
- write a dissector, a function that marks parts of the packet buffer as belonging to fields and adding them to the Wireshark display tree
- register the Proto as a dissector for a given UDP port

[Here's the dissector, written for Wireshark's Lua.](https://github.com/nfirvine/croy-shark)

# Method

This analysis was just passive: I didn't interfere with traffic at all.

I also made a screen recording of the match to correlate events with network traffic.

I wrote [a tool I call "fakereplay"](https://github.com/nfirvine/fakereplay), which simply replays a pcap file in real time given the timing information it contains. I used this to 

To match game events with network events, I made a screen recording of the fake replay, one screen for client→server events, and one screen for server→client events. These were imported into iMovie. I added markers to these clips for interesting events and tried to match them up.

# Observations

- Datagram always starts with what I believe is a session token. Presumably the server on 9339 runs many games and needs to tell them apart somehow.
    - Could play against a friend on another phone to see if token is shared between opponents
- Datagrams appear to be sent on timers rather than based on game events. 
    - From client to server, it's 5Hz; from server to client, 2 Hz.
    - Most of the client → server datagrams are empty (except for the session token); probably a no-op keepalive.
- The first packet with data looks like some sort of initialization: 1387 bytes of `0x00`.
    - 1387 = 19*73; maybe some sort of additional map data? Seems inefficient...
    - The full size of the UDP data is 1400; perhaps testing for MTU?
- There appear to be sequence numbers and ACK commands, and I have witnessed packets being delivered out of order, so there's probably some TCP-like qualities to the protocol. Considering game events require an agreed-upon ordering, this makes sense.
- For the `delta` subcommand (the most interesting type of datagram), we have a length-prefixed string. The contents of the string are unknown to me at time of writing.
    - It looks encrypted; I can't see any pattern. I would guess it's something simple, like `ciphertext = plaintext XOR (session token + seq no)`. Perhaps it is simply compressed. Maybe both.
    - A packet length analysis shows the payloads fit into two size ranges:
        - 7-8: probably unit movement
        - 22-24 (client → server); 30-59 (server → client): probably unit spawning. 
    - each c→s spawn is followed immediately by a s→c spawn. Presumably these datagram pairs contain very similar information. Difference in size ranges from 8-11, with 25 and 30 outliers. This would counterindicate compression or encryption alone.

# Next steps

- Dissect the payload (i.e. crack the encryption :( )
- Figure out a better workflow for marking up videos. There's probably some way to get computer vision involved to detect card plays and unit spawns.
