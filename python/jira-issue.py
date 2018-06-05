#!/usr/bin/env python

"""JIRA Ticket Creation Script

Usage:
  jira-issue.py [-h | --help] --api-auth="<api_auth_header>" --summary="<summary>" --description="<description>" \
                --project="<project_key>" --issue-type="<issue_type>" [--labels=<label>]... [--due-date=YYYY-MM-DD] \
                [--delivery-date=YYYY-MM-DD] [--billing-code=<tenrox_code>] [--time-estimate=<estimate>]
  jira-issue.py --summary <summary> --description <description> --project <project_key>

Options:
  -h --help                                     Show this screen.
  -v --version                                  Show version.
  -a --api-auth=<api_auth_header>               The header text to be used when authenticating ont the API.
  -s --summary=<summary>                        Title of the JIRA issue.
  -d --description=<description>                Description of the JIRA issue.
  -p --project=<project_key>                    The project key
  -t --issue-type=<issue_type>                  The type of JIRA issue.
  -L --labels=<label>                           The list of labels to be added to the issue.
  -D --due-date=<due_date>                      The date that the JIRA issue is due.
  -C --delivery-date=YYYY-MM-DD                 The date of expected delivery.
  -B --billing-code=<tenrox_code>               Tenrox billing code associated with the issue.
  -E --time-estimate=<estimate>                 The amount of time to be estimated on the issue.

"""
# For more information on docopt: https://github.com/docopt/docopt


import json
import urllib2
import sys

# Since 'docopt' isn't a standard Python library, it's necessary to change up the exception handling output to make the
# error more clear.
try:
    from docopt import docopt
except ImportError as detail:
    docopt = None
    print("Error importing 'docopt' module. Please make sure it's installed by running 'pip install docopt'.", detail)
    sys.exit(1)


def main(args):

    # Define some urllib2 options, such as the API URL and the headers.
    api_url = 'https://lyonscg.atlassian.net/rest/api/2/issue/'
    request_headers = {'Content-Type': 'application/json', 'Authorization': args['--api-auth']}

    # Generate basic ticket creation payload.
    create = {
        'fields': {
            'project':
            {
                'key': args['--project']
            },
            'summary': args['--summary'],
            'description': args['--description'],
            'issuetype': {
                'name': args['--issue-type']
            }
        }
    }

    # If the due date is present.
    if args['--due-date']:

        # Set the due date field.
        create['fields']['duedate'] = args['--due-date']

    # If the billing-code is present.
    if args['--billing-code']:

        # Set the billing-code field.
        create['fields']['customfield_10600'] = args['--billing-code']

    # If labels are present.
    if args['--labels']:

        # Set the labels.
        create['fields']['labels'] = args['--labels']

    print('##### TICKET CREATION PAYLOAD')
    print(json.dumps(create, indent=4, sort_keys=True))

    # Build the request using the URL, payload, and headers.
    create_req = urllib2.Request(api_url, json.dumps(create), request_headers)

    # Open an HTTP connection using the request.
    a = urllib2.urlopen(create_req)

    # Get the response and store it.
    create_resp = json.loads(a.read())

    # Close the connection to the host.
    a.close()

    # Grab the ticket details from the API response and store it.
    ticket_url = create_resp['self']

    # Print it out for debugging.
    print('##### TICKET CREATION RESPONSE')
    print(json.dumps(create_resp, indent=4, sort_keys=True))

    # Any of these fields are present, we much update the ticket with the values after creating it.
    if args['--time-estimate'] or args['--delivery-date']:

        # Generate ticket update payload.
        update = {
            'update': {
            }
        }

        # If time estimate is present.
        if args['--time-estimate']:

            # Set the timetracking field.
            update['update']['timetracking'] = [{
                'set': {
                    'originalEstimate': args['--time-estimate'],
                    'remainingEstimate': args['--time-estimate']
                }
            }]

            # Set the custom estimate field.
            update['update']['customfield_10900'] = [{
                'set': float(args['--time-estimate'])
            }]

        # If the delivery date is present.
        if args['--delivery-date']:

            # Set the custom delivery date field.
            update['update']['customfield_12401'] = [{
             'set': args['--delivery-date']
            }]

        # Print out the payload for debugging.
        print('##### TICKET UPDATE PAYLOAD')
        print(json.dumps(update, indent=4, sort_keys=True))

        # Build the request using the URL, payload, and headers.
        update_req = urllib2.Request(ticket_url, json.dumps(update), request_headers)

        # Change the request method to 'PUT'.
        update_req.get_method = lambda: 'PUT'

        # Open an HTTP connection using the request.
        b = urllib2.urlopen(update_req)

        # Get the response and store it.
        update_resp = b.read()

        # Close the connection to the host.
        b.close()

        # Print out the response for debugging.
        print('##### TICKET UPDATE RESPONSE')
        print(update_resp)

if __name__ == '__main__':
    # Store the docopt arguments.
    arguments = docopt(__doc__, version='JIRA Ticket Creation Script')

    # Execute the main body of the script.
    main(arguments)
