#!/usr/bin/env python
""" <otrs2gs.py>: This script is used to import OTRS reports into Google Sheets. """
__author__ = "Ray Tran"

import logging,ConfigParser, csv, glob, os, sys
from datetime import datetime

old_date_time = "2016-03-02 08:40:03"
new_date = old_date_time.split()[0]
new_time = old_date_time.split()[1]
print new_date
print new_time


