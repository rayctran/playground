#!/usr/bin/env python
""" <sysinfo.py>: This script is used to collect information from all the server and vms from LYONSCG environment. """
__author__ = "Ray Tran"

import logging,ConfigParser, csv, glob, os, sys, re
from sheetsync import Sheet, ia_credentials_helper
from datetime import datetime


my_host_file = "/home/rtran/bin/ansible_hosts"

if ( not os.path.isfile(my_host_file) ):
    print ("Error: Hosts file not found\n")
else:
#    infile = open(my_host_file,"r")
#for line in infile:
#    if line.strip() == '' or line[0] in '#;':
#        continue
#    else:
#        if re.match(r'\[(.*?)\]', line):
#            my_env = line.strip()[1:-1]
#        else:
#            dict[my_env] = line;
#            print dict[my_env]

   config = ConfigParser.ConfigParser(allow_no_value=True)
   config.read(my_host_file)
   for client_name in config.sections():
       for ip in config[client_name]:
#          print(ip)
           print (client_name + " " + ip)
