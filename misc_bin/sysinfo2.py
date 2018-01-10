#!/usr/bin/env python
""" <sysinfo.py>: This script is used to collect information from all the server and vms from LYONSCG environment. """
__author__ = "Ray Tran"

import logging,ConfigParser, csv, glob, os, sys, re
import socket
import os 
import sys
import platform
import uuid
from __future__ import print_function
from collections import OrderedDict
from sheetsync import Sheet, ia_credentials_helper
from datetime import datetime


def meminfo():
    ''' Return the information in /proc/meminfo
    as a dictionary '''
    meminfo=OrderedDict()

    with open('/proc/meminfo') as f:
        for line in f:
            meminfo[line.split(':')[0]] = line.split(':')[1].strip()
    return meminfo

if __name__=='__main__':

    meminfo = meminfo()
    print('Total memory: {0}'.format(meminfo['MemTotal']))
    print('Free memory: {0}'.format(meminfo['MemFree']))

    print "Name: "  +socket.gethostname() 
    print "FQDN: "  +socket.getfqdn()
    print "System Platform: "+sys.platform
    print "Machine: " +platform.machine()
    print "Node " +platform.node()
    print "Platform: "+platform.platform()
    print "Pocessor: " +platform.processor()
    print "System OS: "+platform.system()
    print "Release: " +platform.release()
    print "Version: " +platform.version()
    with open('/proc/cpuinfo') as f:
      for line in f:
          print(line.rstrip('\n'))
