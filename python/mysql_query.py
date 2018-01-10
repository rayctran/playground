#!/usr/bin/env python
""" <otrs2gs.py>: This script is used to import OTRS reports into Google Sheets. """
__author__ = "Ray Tran"

import logging,ConfigParser, csv, glob, os, sys
import pymysql
from datetime import datetime

# Builds the connection information for the MySQL database.
connection = pymysql.connect(host='10.0.1.157',
        user='root',
        passwd='azxcde1231',
        db='mdb',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor)




