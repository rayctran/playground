#!/bin/bash -e
# This script is best set to run via cron.d entry as detailed below.
## File Path: /etc/cron.d/oom_disable
## */1 * * * * root /usr/local/bin/oom-disable.sh

# Define our list of OOM Killer exclusions.
OOM_EXCLUSIONS=(
    "crond"
    "sshd"
    "sssd"
    );

# Define the absolute paths for each command.
WHICH=/usr/bin/which
ECHO=`${WHICH} echo`
PGREP=`${WHICH} pgrep`

# Get the total number of indexes in the array.
LEN=${#OOM_EXCLUSIONS[@]}

# Iterate through the list of exclusions.
for (( i=0; i<${LEN}; i++)); do

    # Iterate though each PID found by 'pgrep' for that process.
    for PID in `${PGREP} -f "${OOM_EXCLUSIONS[${i}]}"`;
    do
        # Add an OOM Killer exclusion to the PID.
        ${ECHO} "-17 > /proc/${PID}/oom_adj"
    done
done

# END OF SCRIPT
exit 0