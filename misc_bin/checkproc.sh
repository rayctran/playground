#!/bin/sh

PROCESS="$1"
PROCANDARGS=$*

while :
do
    RESULT=`pgrep ${PROCESS}`

    if [ "${RESULT:-null}" = null ]; then
#            echo "${PROCESS} not running, starting "$PROCANDARGS
            $PROCANDARGS &
             echo "0"
    else
#            echo "running"
            echo "1"
    fi
    sleep 10
done 
