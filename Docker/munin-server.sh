#!/bin/bash

##https://hub.docker.com/r/buildfailure/munin-server

docker run --name munin-server -d -p 8080:8080 -v /var/log/munin:/var/log/munin -v /var/lib/munin:/var/lib/munin -v /var/run/munin:/var/run/munin -v /var/cache/munin:/var/cache/munin -e MUNIN_USER=warren -e MUNIN_PASSWORD=warren -e NODES="server1:192.168.10.8 buildfailure/munin-server
