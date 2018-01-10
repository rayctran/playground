#!/bin/bash

IFS=$'\n'
HOSTS="ansible_hosts"
while read -r host; do
    if [[ "$host" =~ \#.* ]] || [[ "$host" =~ ^\s*$ ]] ; then
        continue
    fi
    if [[ "$host" =~ \[.* ]]; then
        if [[ "$host" =~ ^\[(.*)\]$ ]]; then 
            DOMAIN=${BASH_REMATCH[1]};
            continue
        fi
    fi
    echo "pinging $DOMAIN: host $host"
    OUTPUT="$(ping -c 2 -q $host)"
    echo "out is $OUTPUT"
done < $HOSTS



