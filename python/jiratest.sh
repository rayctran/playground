#!/bin/sh

USER="rtran@lyonscg.com"
PASS="mT7bwujk!7890"
#curl -D- -u $USER:$PASS -X GET -H "Content-Type: application/json" "https://lyonscg.atlassian.net/rest/api/2/issue/AHSR-1469"
#curl -D- -u $USER:$PASS -X GET -H "Content-Type: application/json" "https://lyonscg.atlassian.net/rest/api/2/issue/jql=assignee=rtran"
#curl -D- -u $USER:$PASS -X GET -H "Content-Type: application/json" "https://lyonscg.atlassian.net/rest/api/2/search?jql=project=AHSR&AND&Issuetype&in&("Incident")&AND&Status=New&AND&resolution=Unresolved&ORDER&BY&priority&DESC,&updated&DESC"
#curl -D- -u $USER:$PASS -X GET -H "Content-Type: application/json" "https://lyonscg.atlassian.net/rest/api/2/search?jql=project=AHSR&and&Issuetype=Incident&and&Status=New&AND&resolution=Unresolved"
#curl -D- -u $USER:$PASS -X GET -H "Content-Type: application/json" "https://lyonscg.atlassian.net/rest/api/2/filter/19609"
#curl -i -u $USER:$PASS -H "Content-Type: application/json" -H "Accept: application/json" -X POST -d '{"jql": "project = AHSR and issuetype = Incident and Status = New", "maxResults": 10}' https://lyonscg.atlassian.net/rest/api/2/search |  python -mjson.tool
curl -i -u $USER:$PASS -H "Content-Type: application/json" -H "Accept: application/json" -X POST -d '{"jql": "project = AHSR and issuetype = Incident and Status = New", "maxResults": 10}' https://lyonscg.atlassian.net/rest/api/2/search | sed -e 's/[{}]/''/g' |
    awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}'
