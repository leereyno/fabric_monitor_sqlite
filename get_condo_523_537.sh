#!/bin/bash

for each in $(seq 523 537) ; do

	echo -e -n "or-condo-c${each}\t" 

	ssh or-condo-c${each} "/root/scripts/sqlite_fabric_monitor/fabric_monitor.sh"

done



