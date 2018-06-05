#!/usr/bin/python

import json
import subprocess
import sys

if __name__ == '__main__':
    try:
        proxy_type = sys.argv[1]
    except:
        sys.exit("ZBX_NOTSUPPORTED")

    if proxy_type == 'FRONTEND':
        process = subprocess.Popen("echo 'show stat' | nc -U /var/run/haproxy/admin.sock | awk -F',' '{if ($0 ~ /FRONTEND/) print $1 \",\" $2}'", shell=True, stdout=subprocess.PIPE)
        output = process.communicate()[0].strip().split("\n")
    elif proxy_type == 'BACKEND':
        process = subprocess.Popen("echo 'show stat' | nc -U /var/run/haproxy/admin.sock | awk -F',' '{if ($0 !~ /^#|FRONTEND|^$/) print p=$1\",\"$2}'", shell=True, stdout=subprocess.PIPE)
        output = process.communicate()[0].strip().split("\n")
    else:
        sys.exit("ZBX_NOTSUPPORTED")
