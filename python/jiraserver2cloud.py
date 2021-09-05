#!/usr/bin/python

import glob
import logging
import os
from jira import JIRA
from jira.client import ResultList
from jira.resources import Issue
#from atlassian import Jira
import shutil
import sys
import subprocess
import zipfile
import netrc
from jira.exceptions import JIRAError
import re

jira = JIRA(
        server='https://projects.torcrobotics.com',
        basic_auth=("trictran","53-gh0sTbinary27"),
        )
for issue in jira.search_issues('project = "Information Technology" AND Type not in ("Purchase Request") AND status not in (Closed, Done) AND Resolution in (Unresolved) ORDER BY status ASC',maxResults=300):
    comments = issue.fields.comment.comments
    for comment in comments:
        print("Comment text : ",comment.body)
        print("Comment author : ",comment.author.displayName)
        print("Comment time : ",comment.created)
#    print('working on {}'.format(issue.key))
#     print('{}'.format(issue.fields.comment.comments))

#    print issue.fields.summary
#    tickets = issue.key
#     print('{}: {}'.format(issue.key, issue.fields.summary))

#print(tickets)

#issue = jira.issue('IT-5797',expand="attachment")
#print(issue.fields.attachment)
#for attachment in issue.fields.attachment:
#    with open(attachment.filename, 'wb') as file:
#        file.write(attachment.get())
