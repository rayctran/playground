#!/bin/bash

# Define the absolute paths for each command common between CentOS and Ubuntu.
ECHO=/bin/echo
GIT=/usr/bin/git
WC=/usr/bin/wc

##### GIT CHECK #####
# Check if the web root actually exists.
if [[ -e $1 ]]; then

    # Assign the script input to a variable.
    GITREPO=$1

    ##### GIT COMMANDS #####
    # This 'git' command is a bit safer to run as it is explicitly telling Git where to look rather than relying on it
    # to automatically find the .git folder after changing directories. Using 'cd' would be easier, but it may return
    # unexpected results.
    # 1. Use 'git' to list out the modified/untracked files.
    # 2. Use 'wc' to count the number of modified/untracked files.
    MODIFIED=`${GIT} --git-dir=${GITREPO}/.git --work-tree=${GITREPO} ls-files -m --exclude-standard | ${WC} -l`
    UNTRACKED=`${GIT} --git-dir=${GITREPO}/.git --work-tree=${GITREPO} ls-files -o --exclude-standard | ${WC} -l`

    # Finally, send the results to the Zabbix agent to send back to the Zabbix server.
    ${ECHO} "$GITREPO; $MODIFIED modified file(s); $UNTRACKED untracked file(s);"

else

    # If the webroot provided doesn't exist, send this error message to Zabbix and exit the script with an error code.
    ${ECHO} "Invalid web root: $1"
    exit 1
fi

# END OF SCRIPT
exit 0