#!/bin/bash

# Define the absolute paths for each command common between CentOS and Ubuntu.
WHICH=/usr/bin/which
AWK=`${WHICH} awk`
ECHO=`${WHICH} echo`
FIND=`${WHICH} find`
GIT=`${WHICH} git`
GREP=`${WHICH} grep`
LS=`${WHICH} ls`
SORT=`${WHICH} sort`
TR=`${WHICH} tr`
WC=`${WHICH} wc`

##### FIND WEB ROOTS #####
# This block tests to see if either the Apache or HTTPD directories exist and sets the path accordingly.
# If the '/etc/apache2/sites-enabled' exists, set $WEBSVC to use that directory.
if [[ -d /etc/apache2/sites-enabled ]]; then
    WEBSVC="/etc/apache2/sites-enabled"

# # If the '/etc/httpd/conf.d' exists, set $WEBSVC to use that directory.
elif [[ -d /etc/httpd/conf.d ]]; then
    WEBSVC="/etc/httpd/conf.d"

else
    # Exits with error if neither directory is present.
    ${ECHO} "No Apache install was detected!"
    exit 1
fi

#Pre initialize this variable. The loop will change this later.
WEBROOT="/var/www"

# Iterate through all of the configs to find the web roots.
# 1. Use 'find' to find all of the files that match '*.conf'
# 2. Pipe the output from 'find' into 'sort' and then sort it by name.
CONFIGS=`${FIND} ${WEBSVC} -name *.conf 2>/dev/null | ${SORT} -n`

# Initialize the array.
RAW_WEBROOTLIST=();
RAW_MAGEROOTLIST=();

# For every file found, run these instructions for each.
for FILE in ${CONFIGS}; do

    # Extract the DocumentRoot from the config file.
    # 1. Use 'grep' to search the config file for the first line containing "DocumentRoot".
    # 2. Pipe the output from 'grep' into 'awk' to print the second whitespace-separated value in that line.
    WEBROOT=`${GREP} -m 1 "^\s*DocumentRoot" ${FILE} | ${AWK} '{print $2}'`

    # Makes sure that the config is not for the Deployment Dashboard. It shouldn't check that since the
    # process requires modification to some of the source-controlled files. Doing so would create false alerts.
    if [[ ${WEBROOT} != "/var/www/capapp" ]]; then

        # Check if '.git' exists in that file path.
        if [[ -d ${WEBROOT}/.git ]]; then

            # Add the web root to the next available index in the array.
            RAW_WEBROOTLIST=("${RAW_WEBROOTLIST[@]}" ${WEBROOT})

            # Iterate through all the of the web roots to find Magento.
            # 1. Use 'ls' to find all of the instances of 'Mage.php'
            # 2. Pipe the output from 'ls' into 'sort' and then sort it by name.
            # 3. Pipe the output from 'sort' into 'awk' and separate 'app/Mage.php' from the rest of the file path using
            #     '/' as the delimiter.
            MAGENTO=`${LS} ${WEBROOT}/app/Mage.php ${WEBROOT}/*/app/Mage.php 2>/dev/null | ${SORT} -n | ${AWK} -F'/' NF-=2 OFS='/'`


            # Iterate through the list of Magento roots.
            for MAGEROOT in ${MAGENTO}; do

                # Do a quick check to see if the result is actually a directory.
                if [[ -d ${MAGEROOT} ]]; then

                    # Add the Magento root to the next available index in the array.
                    RAW_MAGEROOTLIST=("${RAW_MAGEROOTLIST[@]}" ${MAGEROOT})

                fi
            done
        fi
    fi
done

##### JSON GENERATOR #####
# Zabbix requires a JSON response for any low-level discovery items. This will structure the list of web roots in a
# manner that allows Zabbix to parse through it.
#
# NOTE: The Magento roots are iterated through first because those are dependant on the web roots. There is no
# Magento root unless there is a web root, but there can be a web root without a Magento root. We can still do our
# git status checks because of this. We'll also add a comma to the end of each Magento entry in the JSON because
# there will be web root entries immediately following the end of that iteration.

# Initialize the $CONTENTS variable.
CONTENTS=''

# Before converting the arrays into JSON, duplicate values must be removed.
# 1. Use 'echo' to send the contents of the array into 'tr'
# 2. The spaces separating each value are stripped and replaced with a new line character.
# 3. The output is sent to the 'sort' function where it moves around the values and outputs only the unique items.
# 4. The new lines separating each value are stripped and replaced with a space using 'tr' again.
# 5. Output from the final 'tr' is placed back into a new array.
MAGEROOTLIST=($(${ECHO} "${RAW_MAGEROOTLIST[@]}" | ${TR} ' ' '\n' | ${SORT} -u | ${TR} '\n' ' '))
WEBROOTLIST=($(${ECHO} "${RAW_WEBROOTLIST[@]}" | ${TR} ' ' '\n' | ${SORT} -u | ${TR} '\n' ' '))

# Test if the array is empty. If is contains items, then proceed.
if [[ ${WEBROOTLIST[0]} != "" ]]; then

    # Get the number of items in the mage root array for use when iterating through it.
    MAGELEN=${#MAGEROOTLIST[@]}

    # Get the number of items in the web root array for use when iterating through it.
    WEBLEN=${#WEBROOTLIST[@]}

    # Start an increment with a maximum based on the total number of items in the array. Increment by one each time.
    for (( i=0; i<${MAGELEN}; i++ )); do

        # Append the next web root and format the JSON with a key called '#MAGEROOTPATH'.
        CONTENTS+="{\"{#MAGEROOTPATH}\":\"${MAGEROOTLIST[$i]}\"},"

    done

    # Start an increment with a maximum based on the total number of items in the array. Increment by one each time.
    for (( i=0; i<${WEBLEN}; i++ )); do

        # Append the next web root and format the JSON with a key called '#WEBROOTPATH'.
        CONTENTS+="{\"{#WEBROOTPATH}\":\"${WEBROOTLIST[$i]}\"}"

        # If the item in the array is not the last item, append a comma. If it is the last item in the array,
        # skip this statement.
        if [ ${i} -lt $((WEBLEN-1)) ]; then
            CONTENTS+=","
        fi
    done
fi

# Send the results to Zabbix.
${ECHO} "{\"data\":[${CONTENTS}]}"

# END OF SCRIPT
exit 0
