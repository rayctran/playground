#!/usr/bin/env python
""" <otrs2gs.py>: This script is used to import OTRS reports into Google Sheets. """
__author__ = "Ray Tran"

import logging,ConfigParser, csv, glob, os, sys
from sheetsync import Sheet, ia_credentials_helper
from datetime import datetime


# Turn on logging so you can see what sheetsync is doing.
logging.getLogger('sheetsync').setLevel(logging.DEBUG)
logging.basicConfig()

from ConfigParser import SafeConfigParser

my_gd_creds_file = "/home/rtran/bin/otrs2gs.ini"

parser = SafeConfigParser()
if ( not os.path.isfile(my_gd_creds_file) ):
    print ("Error: Google Drive creds not found\n")
else:
    parser.read(my_gd_creds_file)

#print 'OTRS_CLIENT_ID:', parser.get('otrs2gs_client', 'OTRS2GS_CLIENT_ID')
#print 'OTRS_CLIENT_SECRET:', parser.get('otrs2gs_client', 'OTRS2GS_CLIENT_SECRET')
otrs2gs_client_id = parser.get('otrs2gs_client', 'OTRS2GS_CLIENT_ID')
otrs2gs_client_secret = parser.get('otrs2gs_client', 'OTRS2GS_CLIENT_SECRET')
creds = ia_credentials_helper(otrs2gs_client_id, otrs2gs_client_secret,
                             credentials_cache_file='cred_cache.json')

#data = { "Kermit": {"Color" : "Green", "Performer" : "Jim Henson"},
#         "Miss Piggy" : {"Color" : "Pink", "Performer" : "Frank Oz"},
#         "Captain Kangaroo" : {"Color" : "Gray", "Performer" : "Ray Tran"},
#        }

# Read in OTRS ticket
my_path = "/home/rtran/otrs_reports"
my_daily_report_file = "/home/rtran/otrs_reports/Daily_Open_Ticket_report"
tickets_list = {}

with open(my_daily_report_file) as my_incoming_data:
    next(my_incoming_data, None)
    next(my_incoming_data, None)
    cvs_read_in = csv.reader(my_incoming_data, delimiter=';', quotechar='"')
    for my_row in cvs_read_in:
            old_date_time = my_row[3]
            new_date = old_date_time.split()[0]
            new_time = old_date_time.split()[1]
            tickets_list[my_row[0]] = [ {'Ticket': my_row[0]}, {'Age': my_row[1]}, \
            {'Title': my_row[2]}, {'Created_Date': new_date}, {'Created_Time': new_time}, \
            {'Queue': my_row[4]}, {'State': my_row[5]}, {'Priority': my_row[6]}, \
            {'CustomerID': my_row[7]}, {'Requested': my_row [8]} ]

for top_keys,top_values in tickets_list.items():
    print top_values
    if isinstance(top_values, dict):
        print top_values
        for k,v in top_values():
            print "%s = %v" %(k, v) 

#for x in tickets_list:
#    print (x)

#raise SystemExit

# Update Google Sheet
target = Sheet(credentials=creds, document_name="AH/Testsync Sheet Getting Started")
target = Sheet(credentials=creds, 
document_key="1DzMggREQOh5Vk7887ur9VMvHXjRyXUSuuQSlVJ8Wv8w",
#	folder_key="0B8U3A23oNm-hU3ZxVTJrYi01X0U",
worksheet_name="MyShiet")
#target.inject(data)
target.inject(tickets_list.items)
print "Spreadsheet created here: %s" % target.document_href
