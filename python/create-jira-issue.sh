#!/usr/bin/env bash

WHICH=/usr/bin/which
CURL=`${WHICH} curl`
DATE=`${WHICH} date`
PYTHON=`${WHICH} python`

TITLE="${RD_OPTION_ISSUE_SUMMARY} for `${DATE} +%D`"
DUEDATE=`${DATE} +%Y-%m-%d`

PAYLOAD='
{
    "fields": {
        "project":
        {
            "key": "'"${RD_OPTION_PROJECT_KEY}"'"
        },
        "summary": "'"${TITLE}"'",
        "description": "'"${RD_OPTION_ISSUE_DESCRIPTION}"'",
        "issuetype": {
            "name": "'"${RD_OPTION_ISSUE_TYPE}"'"
        },
        "labels": [
            "'"${RD_OPTION_ISSUE_LABEL}"'"
        ],
        "duedate": "'"${DUEDATE}"'",
        "customfield_10600": "'"${RD_OPTION_ISSUE_BILLING_CODE}"'"
    }
}
'

RESPONSE=$(${CURL} -X POST --data "${PAYLOAD}" -H "Authorization: ${RD_OPTION_API_CREDENTIALS}" -H "Content-Type: application/json" ${RD_OPTION_JIRA_URL} 2>/dev/null)
echo ${RESPONSE}

ISSUE_URL=$(echo "${RESPONSE}" | ${PYTHON} -c "import sys, json; print json.load(sys.stdin)['self']")
echo ${ISSUE_URL}

UPDATE='
{
    "update": {
        "timetracking": [{
            "set": {
       	        "originalEstimate": "'"${RD_OPTION_ISSUE_TIME_ESTIMATE}"'",
                "remainingEstimate": "'"${RD_OPTION_ISSUE_TIME_ESTIMATE}"'"
            }
        }],
        "customfield_10900": [{
            "set": '"${RD_OPTION_ISSUE_TIME_ESTIMATE}"'
        }],
        "customfield_12401": [{
             "set": "'"${DUEDATE}"'"
        }]
    }
}
'

${CURL} -D- -X PUT --data "${UPDATE}" -H "Authorization: ${RD_OPTION_API_CREDENTIALS}" -H "Content-Type: application/json" ${ISSUE_URL}