#!/bin/sh


# Define Script variables
AUDITDIR=/export/home/audit
HOSTNAME=`hostname`
# Add recipients here separated by spaces
MAILTO="change@me"
#check to make sure the user of the script has changed the mailto address list
if [ $MAILTO = "change@me" ]
then
	echo "Please change the mailto address before running this script" >&2
	exit
fi
DATAFILE=$AUDITDIR/audit_capture_`date '+%Y%m%d_%H%M'`.txt
# Below, add full paths to files that need to be included, separated by spaces
FILELIST="/etc/shadow /etc/security/passwd /etc/passwd /etc/group /etc/default/login /etc/default/passwd /etc/profile /etc/inet/inetd.conf /etc/inetd.conf /etc/ssh/sshd_config /etc/pam.conf /var/adm/sulog /etc/cron.d/cron.allow /etc/cron.d/cron.deny /var/sadm/patch /etc/security/user /etc/sudoers /etc/security/pwdalg.cfg"
# Define variables for Shadow redact
SHADOW="/etc/shadow"
TMPSHADOW1="/export/home/audit/shadow1.tmp"
TMPSHADOW2="/export/home/audit/shadow2.tmp"
AIXSHADOW="/etc/security/passwd"
AIXTMPSHADOW1="/export/home/audit/shadow1.tmp"
AIXTMPSHADOW2="/export/home/audit/shadow2.tmp"
OS=`uname` # Static, do not change
AIX="AIX" # Static, do not change
SUN="SunOS" # Static, do not change
LINUX="Linux" # Static, do not change


#######################################################################################
#######################################################################################

# Test if $AUDITDIR exists, and creates it if not.
if [ -d "$AUDITDIR" ]

	then

		echo
		echo "\"$AUDITDIR\" already exists."
	
	else

		mkdir -p $AUDITDIR
		
		echo
		echo "\"$AUDITDIR\" created successfully!"
	
fi

# Spacing
echo

#######################################################################################
#######################################################################################

# Create $DATAFILE to store information
touch $DATAFILE

#######################################################################################
#######################################################################################

# Captures permissions and contents of each file in the $FILELIST variable and appends the info to $DATAFILE
for i in $FILELIST

	do

		if [ "$i" = "$SHADOW" ];
		
			then
				
					echo "# ls -la $SHADOW" >> $DATAFILE
					ls -la $SHADOW >> $DATAFILE
					echo "=================================================================" >> $DATAFILE

					# Copy contents of "/etc/shadow" to $TMPSHADOW1 location, redact password hash, and copy new contents to $TMPSHADOW2
					cat $SHADOW > $TMPSHADOW1
					cat $TMPSHADOW1 | awk -F: '{ print $1":XXXX:"$3":"$4":"$5":"$6":"$7":"$8":" }' > $TMPSHADOW2
						
					# Capture redacted shadow info and append to $DATAFILE
					echo "# cat $SHADOW" >> $DATAFILE
					cat $TMPSHADOW2 >> $DATAFILE
					echo "=================================================================" >> $DATAFILE

					echo $SHADOW Successfully sent to $DATAFILE
					echo $i is shadow
					echo

					# Remove $TMPSHADOW and $TMPSHADOW2
					rm $TMPSHADOW1
					rm $TMPSHADOW2
					
		elif [ "$i" = "$AIXSHADOW" ];
		
			then
			
					echo "# ls -la $AIXSHADOW" >> $DATAFILE
					ls -la $AIXSHADOW >> $DATAFILE
					echo "=================================================================" >> $DATAFILE

					# Copy contents of "/etc/shadow" to $AIXTMPSHADOW1 location, redact password hash, and copy new contents to $AIXTMPSHADOW2
						cat $AIXSHADOW > $AIXTMPSHADOW1
						cat $AIXTMPSHADOW1 | awk '{ if ( $1 == "password" && length($3) >1 ) { $3="XXXX" } print $1$2$3; }' > $AIXTMPSHADOW2
						
					# Capture redacted shadow info and append to $DATAFILE
						echo "# cat $AIXSHADOW" >> $DATAFILE
						cat $AIXTMPSHADOW2 >> $DATAFILE
						echo "=================================================================" >> $DATAFILE

					# Remove $AIXTMPSHADOW and $AIXTMPSHADOW2
						rm $AIXTMPSHADOW1
						rm $AIXTMPSHADOW2
		
		
		elif [ -d "$i" ] && [ "$i" != "$SHADOW" ] && [ "$i" != "$AIXSHADOW" ];
				
			then
					
					# List permissions and contents of a directory
					echo "# ls -la $i" >> $DATAFILE
					ls -la $i >> $DATAFILE
					echo "=================================================================" >> $DATAFILE

					#Prints output to console upon successful data collection
					echo $i Successfully sent to $DATAFILE
					echo $i is a directory
					echo
					
		
		elif [ -f "$i" ] && [ ! -d "$i" ] && [ "$i" != "$SHADOW" ] && [ "$i" != "$AIXSHADOW" ];
		
			then
					
					# List permissions and contents for a file
					echo "# ls -la $i" >> $DATAFILE
					ls -la $i >> $DATAFILE
					echo "=================================================================" >> $DATAFILE
					
					echo "# cat $i" >> $DATAFILE
					cat $i >> $DATAFILE
					echo "=================================================================" >> $DATAFILE
					
					#Prints output to console upon successful data collection
					echo $i Successfully sent to $DATAFILE
					echo $i is a file
					echo
					
		else
					# Prints output to console and to $DATAFILE if file in $FILELIST does not exist
					echo "$i does not exist on this system" >> $DATAFILE
					echo "=================================================================" >> $DATAFILE
					
					echo "$i does not exist on this system"
					echo
					
		fi
					
done

# List output of the 'last' command
echo "# last" >> $DATAFILE
last >> $DATAFILE
echo "=================================================================" >> $DATAFILE

echo "\"last\" command Successfully sent to "$DATAFILE
echo

# List output of the 'oslevel -s' command
echo "# oslevel -s" >> $DATAFILE
oslevel -s >> $DATAFILE
echo "=================================================================" >> $DATAFILE

echo "\"oslevel -s\" command Successfully sent to "$DATAFILE
echo

# Test for OS & define OS specific commands
case $OS in

	$AIX) 
	
		echo "# lslpp -h" >> $DATAFILE
		lslpp -h >> $DATAFILE
		echo "=================================================================" >> $DATAFILE

		echo "\"lslpp -h\" command Successfully sent to "$DATAFILE
		echo
		;;
	
	$SUN) ;;
	
	$LINUX) ;;
	*) 
	
	exit
	;;
	
esac

# Mail contents of $DATAFILE to recipients listed in $MAILTO
cat $DATAFILE | mailx -s "[SOX Audit Data | "`date '+%m-%d-%Y'`"] $HOSTNAME" $MAILTO