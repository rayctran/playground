#!/usr/bin/env python
""" <otrs2gs.py>: This script is used to import OTRS reports into Google Sheets. """
__author__ = "Ray Tran"

import gspread
import json

#gspread-3cc454537eb0.json
#from oauth2client.client import SignedJwtAssertionCredentials

#json_key = json.load(open('gspread-3cc454537eb0.json'))
#scope = ['https://spreadsheets.google.com/feeds']

#credentials = SignedJwtAssertionCredentials(json_key['client_email'], json_key['private_key'].encode(), scope)

#gc = gspread.authorize(credentials)

c = gspread.Client(auth=('rtran@lyonscg.com', 'mT7bwujk!7890'))
c.login()
c.open('Testsync Sheet Getting Started')

