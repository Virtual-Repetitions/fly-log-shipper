#!/bin/bash
set -e
trap 'kill $(jobs -p)' EXIT

vector -c /etc/vector/vector.toml &
while [ ! -e /var/run/vector.sock ]; do
  sleep 0.5
done
/usr/local/bin/fly-logs | socat -u - UNIX-CONNECT:/var/run/vector.sock
