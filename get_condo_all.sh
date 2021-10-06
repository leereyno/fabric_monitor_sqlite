#!/bin/bash

# Handles nodes with double digit names less than 10
for each in $(seq -w 00 09) ; do

	echo -e -n "or-condo-c${each}\t" 

	ssh or-condo-c${each} "/root/scripts/sqlite_fabric_monitor/fabric_monitor.sh"

done

for each in $(seq 10 546) ; do

	echo -e -n "or-condo-c${each}\t" 

	ssh or-condo-c${each} "/root/scripts/sqlite_fabric_monitor/fabric_monitor.sh"

done



