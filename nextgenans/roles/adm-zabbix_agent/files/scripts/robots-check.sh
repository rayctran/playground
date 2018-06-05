#!/bin/bash

# Define the absolute paths for each command common between CentOS and Ubuntu.
CAT=/bin/cat
ECHO=/bin/echo

if [[ -e $1 ]]; then

    # Assign the script input to a variable.
    WEBROOT=$1

    # Set the path to robots.txt based on the webroot provided.
    ROBOTS_TXT="${WEBROOT}/robots.txt"
    ROBOTS_PHP="${WEBROOT}/robots.php"

    # Check if robots.txt exists at that specific path. Proceed if it's true.
    if [[ -e ${ROBOTS_TXT} || -e ${ROBOTS_PHP} ]]; then

        if [[ -e ${ROBOTS_TXT} ]]; then

            # Get the contents of robots.txt
            # 1. Use 'cat' to save the contents of robots.txt to a variable.
            CONTENTS=`${CAT} ${ROBOTS_TXT}`

        elif [[ -e ${ROBOTS_PHP} ]]; then

            # Get the contents of robots.php
            # 1. Use 'cat' to save the contents of robots.txt to a variable.
            CONTENTS=`${CAT} ${ROBOTS_PHP}`

        fi

        # Check if robots.txt is empty.
        if [[ ${CONTENTS} == '' ]]; then

            # Set the status to 'empty' if true.
            STATUS="robots.txt is empty."

        else

            # Set the status to 'present' if content exists.
            STATUS="robots.txt is present."
        fi
    else

        # Set the status to 'not found' if robots.txt does not exist.
        STATUS="robots.txt does not exist."
    fi

    # Send the results of the check to Zabbix for processing.
    ${ECHO} "${STATUS}"

else

    # If the webroot provided doesn't exist, send this error message to Zabbix and exit the script with an error code.
    ${ECHO} "Invalid web root: $1"
    exit 1
fi

# END OF SCRIPT
exit 0