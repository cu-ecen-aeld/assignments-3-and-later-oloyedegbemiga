#!/bin/sh
# Tester script for assignment 1 and assignment 2
# Author: Siddhant Jajoo

set -e
set -u

NUMFILES=10
WRITESTR="AELD_IS_FUN"
WRITEDIR="/tmp/aeld-data"
CONFIG_DIR="/etc/finder-app/conf"

username=$(cat "${CONFIG_DIR}/username.txt")
assignment=$(cat "${CONFIG_DIR}/assignment.txt")

if [ "$#" -lt 3 ]; then
    echo "Using default value ${WRITESTR} for string to write"

    if [ "$#" -lt 1 ]; then
        echo "Using default value ${NUMFILES} for number of files to write"
    else
        NUMFILES="$1"
    fi
else
    NUMFILES="$1"
    WRITESTR="$2"
    WRITEDIR="/tmp/aeld-data/$3"
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"

rm -rf "${WRITEDIR}"

# Create WRITEDIR for assignments other than assignment1.
if [ "${assignment}" != "assignment1" ]; then
    mkdir -p "${WRITEDIR}"

    if [ -d "${WRITEDIR}" ]; then
        echo "${WRITEDIR} created"
    else
        echo "Error: could not create ${WRITEDIR}"
        exit 1
    fi
fi

i=1
while [ "${i}" -le "${NUMFILES}" ]; do
    # writer is located using PATH.
    writer "${WRITEDIR}/${username}${i}.txt" "${WRITESTR}"
    i=$((i + 1))
done

# finder.sh is located using PATH.
# OUTPUTSTRING=$(finder.sh "${WRITEDIR}" "${WRITESTR}")
OUTPUTSTRING=$(finder.sh "${WRITEDIR}" "${WRITESTR}")
printf '%s\n' "${OUTPUTSTRING}" > /tmp/assignment4-result.txt

# Remove temporary directories.
rm -rf "/tmp/aeld-data"

if printf '%s\n' "${OUTPUTSTRING}" | grep -q "${MATCHSTR}"; then
    echo "success"
    exit 0
else
    echo "failed: expected ${MATCHSTR} in ${OUTPUTSTRING} but instead found"
    exit 1
fi