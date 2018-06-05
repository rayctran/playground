#!/bin/bash

# Define the absolute paths for each command common between CentOS and Ubuntu.
ECHO=/bin/echo
GREP=/bin/grep
SED=/bin/sed

if [[ -e $1 ]]; then

    # Assign the script input to a variable.
    MAGEROOT=$1

    ##### CONFIG FILES #####
    # Define the list of .htaccess files relative to the Magento root.
    #
    # NOTE: According to best practices and security for Magento applications, nothing in this list should be removed.
    # There are mechanisms within this script to handle any directories do not exist by default. Thus, in most cases,
    # any changes to this list of .htaccess files would only be additional entries. Please seek approval from a Senior
    # Systems Administrator before making any changes.
    HTACCESS_FILES=(
        ".htaccess"
        "app/.htaccess"
        "downloader/.htaccess"
        "downloader/template/.htaccess"
        "errors/.htaccess"
        "environment/.htaccess"
        "includes/.htaccess"
        "lib/.htaccess"
        "media/.htaccess"
        "media/customer/.htaccess"
        "media/downloadable/.htaccess"
        "pkginfo/.htaccess"
        "skin/.htaccess"
        "skin/frontend/rwd/default/scss/.htaccess"
        "skin/frontend/rwd/enterprise/scss/.htaccess"
        "var/.htaccess"
        "__tools__/.htaccess"
        );

    # Get the total number of indexes in the array.
    LEN=${#HTACCESS_FILES[@]}

    # Set empty variables before entering the loop.
    EMPTY_FILES=''
    MISSING_FILES=''

    # Iterate through the list of .htaccess files.
    for (( i=0; i<${LEN}; i++ )); do

        # Set the path to the .htaccess file based on the Magento root.
        HTACCESS_PATH="${MAGEROOT}/${HTACCESS_FILES[${i}]}"

        # Set the directory for the .htaccess file, so that we can handle any missing directories.
        # 1. Use 'echo' to pipe the path into 'sed'.
        # 2. Use 'sed' to remove .htaccess from the end of the path to get the directory.
        HTACCESS_DIR=`${ECHO} "${HTACCESS_PATH}" | ${SED} 's/.htaccess//g'`

        # If the directory that .htaccess resides is a directory that exists, proceed.
        if [[ -d ${HTACCESS_DIR} ]]; then

            # If the path to the .htaccess file exists, proceed.
            if [[ -e ${HTACCESS_PATH} ]]; then

                # If the .htaccess file exists in 'media', proceed.
                if [[ ${HTACCESS_FILES[${i}]} == "media/.htaccess" ]]; then

                    # Find 'get.php' inside the .htaccess file
                    # 1. Use 'grep' to find the line that contains 'get.php'
                    CONTENTS=`${GREP} -i 'get.php' ${HTACCESS_PATH}`

                elif [[ ${HTACCESS_FILES[${i}]} == "skin/.htaccess" ]]; then

                    # Find 'get.php' inside the .htaccess file
                    # 1. Use 'grep' to find the line that contains 'get.php'
                    CONTENTS=`${GREP} -i 'php_flag' ${HTACCESS_PATH}`

                # If the .htaccess file is not in 'media', then proceed here.
                else

                    # Find 'Deny from all' inside the .htaccess file
                    # 1. Use 'grep' to find the line that contains 'Deny from all'
                    CONTENTS=`${GREP} -i "Deny from all" ${HTACCESS_PATH}`
                fi

                # If 'grep' did not return any lines, then proceed.
                if [[ ${CONTENTS} == '' ]]; then

                    # Add the path to the .htaccess file to the list of empty files.
                    EMPTY_FILES+=" ${HTACCESS_FILES[${i}]};"
                fi

            # If the .htaccess file does not exist where if should, proceed here.
            else

                # Add the path to the .htaccess file to the list of missing files.
                MISSING_FILES+=" ${HTACCESS_FILES[${i}]};"
            fi
        fi
    done

    # If there are empty of missing files, proceed.
    if [[ ${EMPTY_FILES} != '' || ${MISSING_FILES} != '' ]]; then

        # Send the results to Zabbix.
        echo "EMPTY FILES: ${EMPTY_FILES}"
        echo "MISSING FILES: ${MISSING_FILES}"

    # If there are no empty or missing files, then proceed here.
    else

        # Send the results to Zabbix.
        echo "No missing or empty files."
    fi

else

    # If the webroot provided doesn't exist, send this error message to Zabbix and exit the script with an error code.
    ${ECHO} "Invalid magento root: $1"
    exit 1
fi

# END OF SCRIPT
exit 0