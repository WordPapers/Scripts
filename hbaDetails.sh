#!/bin/bash

##    Gets details about all HBAs present to the OS
##    Tested on:
##       Red Hat Enterprise Linux Server release 5.5 (Tikanga)

##    Author: Ian Rudie
##	Revision History
##	1.0 - basic functionality and emulex detail
##		error handling
##		2012/1/5 - IR
##
##	1.1 - imporved modularity and design
##		2012/1/10 - IR

##BEGIN EMULEX DETAIL
#@FUNCTION emulexDetail
#@USAGE emulexDetail $HBA
#@ARGUMENT $HBA - the name of the directoy under /sys/class/fc_host/ which represents an HBA port
emulexDetail () { 

#create emulex detail header format string
EDHEADFORMAT="%12s %4s %6s %3s %8s %14s"

#catch faulty calls with no argument
if [ ! $1 ] 
then
	#print an error stating that no argument was supplied
	echo >&2
	echo "Improper use of function emulexDetail; no argument supplied" >&2
	#return
	return
#catch if argument is header; print header
elif [ $1 =  "HEADER" ]
then
	#print header
	printf "$EDHEADFORMAT" "Model" "LQD" "QD" "TMO" "FW Rev" "Driver" 2>/dev/null
	return
#catch if argument supplied is actually a valid HBA
elif [ ! -d /sys/class/scsi_host/${1}  ]
then
	#print an error stating that argument is not valid
	echo >&2
	echo "Improper use of function emulexDetail; argument supplied is invalid: " $1 >&2
	return
fi
#exception catching done! let's get some data

#set HBA from argument 1
HBA=$1

#get model name
MODELNAME=`cat /sys/class/scsi_host/${HBA}/modelname 2>/dev/null`
#get LUN Queue Depth
LQD=`cat /sys/class/scsi_host/${HBA}/lpfc_lun_queue_depth 2>/dev/null`
#get HBA Queue Depth
QD=`cat /sys/class/scsi_host/${HBA}/lpfc_hba_queue_depth 2>/dev/null`
#get Timeout
TMO=`cat /sys/class/scsi_host/${HBA}/lpfc_devloss_tmo 2>/dev/null`
#get Firmware Revision
FWREV=`cat /sys/class/scsi_host/${HBA}/fwrev | awk '{print $1}' 2>/dev/null`
#get Driver Revision
DRREV=`cat /sys/class/scsi_host/${HBA}/lpfc_drvr_version | awk '{print $NF}' 2>/dev/null`

#print emulex detail
printf "$EDHEADFORMAT" $MODELNAME $LQD $QD $TMO $FWREV $DRREV 2>/dev/null

}
##END EMULEX DETAIL

##BEGIN DETECT EMULEX
#@FUNCTION detectEmulex
#@USAGE detectEmulex
#@NOARGUMENT

detectEmulex () {

#look for files with lpfc (Light Pulse Fibre Channel)
if [[ 0 -lt $(ls /sys/class/scsi_host/host*/ | grep lpfc | wc -l 2>/dev/null) ]]
then
	return $(true)
else
	return $(false)
fi

}
##END DETECT EMULEX

##BEGIN MAIN
#create standard header format string
SHEADFORMAT="%6s %24s %8s %6s"
#print standard header
printf "$SHEADFORMAT" "HBA" "WWPN" "State" "Speed" 2>/dev/null

#detect emulex cards
if detectEmulex
then
	#print emulex header
	emulexDetail "HEADER"
fi

#header complete; newline
echo

#get list of HBAs
HBAS=`ls /sys/class/fc_host/ 2>/dev/null`

#iterate on each HBA
for HBA in $HBAS ;
do
	#get WWPN; reformat it "brocade style"
	WWN=`cat /sys/class/fc_host/${HBA}/port_name |sed -e 's/\(0x\)*\([a-fA-F0-9]\{2\}\)/\2\:/g' -e 's/\:$//' 2>/dev/null`
	#get HBA state
	STATE=`cat /sys/class/fc_host/${HBA}/port_state 2>/dev/null`
	#get HBA speed
	SPEED=`cat /sys/class/fc_host/${HBA}/speed | awk '{print $1}' 2>/dev/null`
	#print standard information
	printf "$SHEADFORMAT" $HBA $WWN $STATE $SPEED 2>/dev/null
	#detect emulex cards
	if detectEmulex
	then
		#print the details output for this emulex HBA
		emulexDetail $HBA
	fi
	#newline
	echo
	
done
##END MAIN

###NOTES
