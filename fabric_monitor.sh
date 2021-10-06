#!/bin/bash

# Paranoia
sync
sync
sync

# Lee Reynolds <Lee.Reynolds@asu.edu>
# ASU Research Computing

set -u # Define variables before use

#set -x # Get loud

# What is our real path name
REALPATH="$(readlink -f $0 | xargs dirname)"

# Full path to database file
DB="${REALPATH}/database.db"

# Can't run without initialized database file
if [ ! -e $DB ] ; then
	echo -e "\nThe database file $DB does not exist, use initdb.sh to create it\n"
	exit 1
fi

SQLITE3="$(which sqlite3)"

DBCON="$SQLITE3 -batch $DB" 

echo $DBCON

DEBUGGER=false

ALLQUERY=""

############################
# Get host information
############################

#echo "1" > 1

NOW=$(date +%s)

UUID=$(cat /sys/class/dmi/id/product_uuid)
FULLHOSTNAME=$(hostname)

# This will generate results on ubuntu and centos 7.x and above
# Centos 6.x will show up as unknown
if [ -e /etc/os-release ] ; then
	OSFLAVOR="$(grep '^ID=' /etc/os-release | awk -F'=' '{ print $2 }' | sed -e 's/"//g')"
	OSVERSION="$(grep '^VERSION_ID' /etc/os-release | awk -F'=' '{ print $2 }' | sed -e 's/"//g')"
else
	OSFLAVOR="unknown"
	OSVERSION="unknown"
fi

# If we're running centos then get the exact version number
if [ -e /etc/centos-release ] ; then

	if [ $OSFLAVOR = "unknown" ] ; then
		OSFLAVOR="centos"
	fi

	CENTOSVERSION=$(grep -o [[:digit:]]\.[[:digit:]]*\.[[:digit:]]* /etc/centos-release)

	if [ "$OSVERSION" = "unknown" ] ; then
		OSVERSION="$CENTOSVERSION"
	fi

else
	CENTOSVERSION="0"
fi

#echo "2" > 2

KERNEL="$(uname -r)"
VENDOR="$(cat /sys/devices/virtual/dmi/id/sys_vendor)"
MODEL="$(cat /sys/devices/virtual/dmi/id/product_name)"
SERIAL="$(cat /sys/devices/virtual/dmi/id/product_serial)"
BIOSDATE="$(cat /sys/devices/virtual/dmi/id/bios_date)"
BIOSVEND="$(cat /sys/devices/virtual/dmi/id/bios_vendor)"
BIOSVER="$(cat /sys/devices/virtual/dmi/id/bios_version)"

# If there is no infiniband directory, then this system has neither IB nor OPA
if [ ! -d /sys/class/infiniband ] ; then
	INFINIBAND="0"
	OMNIPATH="0"
   OPAVERSION="0"
else
	# There is an infiniband directory, so we need to do extra work

	# hfi1_0 cards are always omnipath
	if [ -e /sys/class/infiniband/hfi1_0 ] ; then
		OMNIPATH="1"

        OPAVERSION=$(rpm -q --queryformat "%{VERSION}\n" opa-basic-tools)

        if [ $? -ne 0 ] ; then
            OPAVERSION="ERROR GETTING OPAVERSION"
        fi

	else
		OMNIPATH="0"
        OPAVERSION="0"
	fi

	# Assume we do not have infiniband
	INFINIBAND="0"

    # Search through all of the non omnipath ports and see if any are
    # Infiniband ports
	for module in $(/bin/ls -1 /sys/class/infiniband/ | grep -v hfi1 ) ; do
        for port in $(/bin/ls -1 /sys/class/infiniband/$module/ports/ ) ; do
            if [ -e /sys/class/infiniband/$module/ports/$port/link_layer ] ; then
                if [ "$(cat /sys/class/infiniband/$module/ports/$port/link_layer)" = "InfiniBand" ] ; then
                    INFINIBAND="1"
                fi
            fi
        done
	done
fi

#echo "3" > 3

# Find out whether smt (hyperthreading) is turned on
if [ -e /sys/devices/system/cpu/smt/active ] ; then
	SMT=$(cat /sys/devices/system/cpu/smt/active)
else
	SMT=2 # Means we do not know
fi

HOSTQUERY="replace into hosts values
	(\"$UUID\",
	\"$FULLHOSTNAME\",
	\"$OSFLAVOR\",
	\"$OSVERSION\",
	\"$CENTOSVERSION\",
	\"$KERNEL\",
	\"$VENDOR\",
	\"$MODEL\",
	\"$SERIAL\",
	\"$BIOSDATE\",
	\"$BIOSVEND\",
	\"$BIOSVER\",
	\"$INFINIBAND\",
	\"$OMNIPATH\",
   \"$OPAVERSION\",
	\"$SMT\",
	\"$NOW\")"

	ALLQUERY="$HOSTQUERY"

if [ $DEBUGGER = true ] ; then
	echo "HOSTQUERY : $HOSTQUERY"
	$DBCON "$HOSTQUERY" 
else
	true
	$DBCON "$HOSTQUERY"
fi

###################################
# Get device and port information
###################################

# Process all IB ports
if [ -d /sys/class/infiniband ] ; then

	cd /sys/class/infiniband

	DEVICEROOT=$(pwd)

	for DEVICE in $(/bin/ls -1) ; do

		cd $DEVICE

		BOARD_ID=$(cat board_id)

		if [ -e fw_ver ] ; then
			FW_VER="$(cat fw_ver)"
		else
			FW_VER="0"
		fi

		if [ -e hca_type ] ; then
			HCA_TYPE="$(cat hca_type)"
		else
			HCA_TYPE="0"
		fi

		DEVICEQUERY="replace into devices values
		(\"$UUID\",
		\"$DEVICE\",
		\"$BOARD_ID\",
		\"$FW_VER\",
		\"$HCA_TYPE\",
		\"$NOW\")"

		ALLQUERY="${ALLQUERY}; $DEVICEQUERY"

		if [ $DEBUGGER = true ] ; then
			echo "DEVICEQUERY : $DEVICEQUERY"
			$DBCON "$DEVICEQUERY" 
		else
			true
			$DBCON "$DEVICEQUERY"
		fi

		########################
		## Get port Information
		########################

		cd ports

		PORTROOT=$(pwd)

		for PORT in $(/bin/ls -1) ; do

			cd $PORT

			LID="$(cat lid)"

			if [ "$DEVICE" = "hfi1_0" ] ; then
				LINK_LAYER="OmniPath"
			else
				LINK_LAYER="$(cat link_layer)"
			fi

			PHYS_STATE="$(cat phys_state)"
			RATE="$(cat rate)"
			SM_LID="$(cat sm_lid)"
			STATE="$(cat state)"
			
			
			PORTQUERY="replace into ports values
			(\"$UUID\",
			\"$DEVICE\",
			\"$PORT\",
			\"$LID\",
			\"$LINK_LAYER\",
			\"$PHYS_STATE\",
			\"$RATE\",
			\"$SM_LID\",
			\"$STATE\",
			\"$NOW\")"

			ALLQUERY="${ALLQUERY}; $PORTQUERY"

			if [ $DEBUGGER = true ] ; then
				echo "PORTQUERY : $PORTQUERY"
				$DBCON "$PORTQUERY" 
			else
				true
				$DBCON "$PORTQUERY"
			fi

			cd $PORTROOT

		done

		cd $DEVICEROOT
		
	done
fi

# Get IP info
if [ -d /sys/class/net ] ; then

	cd /sys/class/net

	DEVICEROOT=$(pwd)

	for DEVICE in $(/bin/ls -1) ; do

		cd $DEVICE 2>/dev/null

        if [ $? -eq 0 ] ; then

            MAC=$(cat address)
            IP=$(ip a s $DEVICE | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)
            NETMASK=$(ip a s $DEVICE | grep 'inet ' | egrep -o '/[0-9]{1,3}')
            DUPLEX=$(cat duplex 2>/dev/null)
            MTU=$(cat mtu 2>/dev/null)
            OPERSTATE=$(cat operstate 2>/dev/null)
            SPEED=$(cat speed 2>/dev/null)

            IPQUERY="replace into ip_info values
            (\"$UUID\",
            \"$DEVICE\",
            \"$MAC\",
            \"$IP\",
            \"$NETMASK\",
            \"$DUPLEX\",
            \"$MTU\",
            \"$OPERSTATE\",
            \"$SPEED\",
            \"$NOW\")"

				ALLQUERY="${ALLQUERY}; $IPQUERY"

            if [ $DEBUGGER = true ] ; then
					echo "IPQUERY : $IPQUERY"
					$DBCON "$IPQUERY" 
            else
					true
               $DBCON "$IPQUERY"
            fi
        fi
		cd $DEVICEROOT
	done

fi

#echo $ALLQUERY
#$DBCON "$ALLQUERY"

# Paranoia
sync
sync
sync

