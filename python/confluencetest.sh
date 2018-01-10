#!/bin/sh

USER="tran@lyonscg.com"
PASSWD="mT7bwujk!7890"

curl -u $USER:$PASSWD -X PUT -H 'Content-Type: application/json' -d'{"id":"123209351","type":"page","title":"Confluence Test Connector","space":{"key":"~tran@lyonscg.com"},"body":{"storage":{"value":"<p>This is the updated text for the new page</p>","representation":"storage"}},"version":{"number":2}}' https://lyonscg.atlassian.net/confluence/rest/api/content/123209351 | python -mjson.tool
