#!/bin/bash

IFS=$'\n'
#HOSTS="ansible_hosts"
HOSTS="ansible_hosts"
#HOSTS="my_hosts"
while read -r host; do
    echo  $host
    if [[ "$host" =~ \#.* ]] || [[ "$host" =~ ^\s*$ ]] ; then
        continue
    fi
    if [[ "$host" =~ \[.* ]]; then
        if [[ "$host" =~ ^\[(.*)\]$ ]]; then
            DOMAIN=${BASH_REMATCH[1]};
            continue
        fi
    fi
    OUTPUT="$(ping -c 2 $host)"
    RETVAL=$?
    if [[ $RETVAL = 0 ]]; then
        echo "checking $DOMAIN: host $host"
        OUTPUT="$(ssh -o ConnectTimeout=1 $host 'bash -s' < uname.sh)"
        echo $OUTPUT
#        OUTPUT="$(ssh -o ConnectTimeout=1 $host 'bash -s' < main.sh)"
#        if [[ "$OUTPUT" > 0 ]]; then
#            echo "Read-only file system detected for $DOMAIN: host $host"
#        fi
        OUTPUT="$(ssh -o ConnectTimeout=1 $host 'bash -s' < last.sh)"
        echo $OUTPUT
    fi

done < $HOSTS

