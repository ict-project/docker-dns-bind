#!/bin/sh

touch /data/named.conf.zones

exec /usr/sbin/named -g
