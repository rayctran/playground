#!/usr/bin/python

import sys, string, xmlrpclib, re

#!/usr/bin/python
#
# Reads from standard input, dumps it onto a Confluence page
# You'll need to modify the URL/username/password/spacekey/page title
# below, because I'm too lazy to bother with argv.
import sys
from xmlrpclib import Server

# Read the text of the page from standard input
#content = sys.stdin.read()
content = "This is a test"

s = Server("https://lyonscg.atlassian.net/wiki/rpc/xmlrpc")
token = s.confluence1.login('rtran@lyonscg.com','mT7bwujk!7890')
page = s.confluence1.getPage(token, "AHTS", "Test Page")
page["content"] = content
s.confluence1.storePage(token, page)


#server = xmlrpclib.ServerProxy('https://lyonscgahdev.atlassioan.net/confluence/rpc/xmlrpc');
#token = server.confluence1.login('rayctran', 'pb4ugo2bed!7890');
#page = server.confluence1.getPage(token, AHTS, "Test Page");
#if page is None:
#   exit("Could not find page " + spacekey + ":" + pagetitle);
#
#content = "This is a test page"
#
#page['content'] = content;
#server.confluence1.storePage(token, page);
