#!/bin/bash

#Gets info for a set of or-condo-cXXX nodes based on start and stop numbers

if [ $# -lt 2 ] ; then
	echo -e "\nGotta give me a range\n"
	echo -e "e.g. $(basename $0) 00 10\n"
	exit 1
fi

FIRSTWIDTH=$(echo -n "$1" | wc -m)
SECONDWIDTH=$(echo -n "$2" | wc -m)

if [ $FIRSTWIDTH -ne $SECONDWIDTH ] || [ $FIRSTWIDTH -le 2 ] ; then
	SEQFLAGS="-w"
fi

# Handles nodes with double digit names less than 10
for each in $(seq $SEQFLAGS $1 $2) ; do

	echo -e -n "or-condo-c${each}\t" 

	ssh or-condo-c${each} "/root/scripts/sqlite_fabric_monitor/fabric_monitor.sh"

done

