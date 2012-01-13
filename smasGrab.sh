#!/bin/bash

#Collect SMAS logs
#	Author: Ian Rudie

#Create list of files to include, every line should end in \ inside the quotes ("")
INCLUDEFILES="\
/opt/emc/SMAS/installerlogs/EMC_SMAS_INSTALL_*.log \
/opt/emc/SMAS/jboss/bin/run.log \
/opt/emc/SMAS/jboss/bin/run_B1.log \
/opt/emc/SMAS/jboss/bin/shutdown.log \
/opt/emc/SMAS/jboss/server/default-em/log/* \
/opt/emc/SMAS/jboss/server/default-em/deploy/smc.ear/smc.war/WEB-INF/logs/litewave.trc* \
/opt/emc/SMAS/jboss/server/default-em/deploy/spa.ear/spa.war/WEB-INF/logs/litewave.trc* \
/opt/emc/SMAS/jboss/server/default-em/deploy/spa.ear/spa.war/WEB-INF/logs/SPAPerformance.log* \
/opt/emc/SMAS/jboss/server/default-em/data/msq/data/$(hostname).err \
/opt/emc/SMAS/jboss/server/default-em/data/msq/my.ini \
/opt/emc/SMAS/jboss/server/default-em/data/msq/my.cnf \
/opt/emc/SMAS/jboss/server/default-em/deploy/smc.ear/smc.war/WEB-INF/eccweb.ini \
/opt/emc/SMAS/jboss/server/default-em/deploy/spa.ear/spa.war/WEB-INF/eccweb.ini \
/opt/emc/SMAS/jboss/server/default-em/data/auditlog/* \
/opt/emc/SMAS/jboss/bin/hs_*.err \
/opt/emc/SMAS/jboss/server/default-em/deploy/domain-symm.ear/domain-symm-ejb.jar/META-INF/jboss.xml \
/opt/emc/SMAS/jboss/server/default-em/deploy/spa-ds.xml \
"
#create a timestamp with no spaces
TIMESTAMP=$( date +"%Y%m%d.%H%M%S" )
#set short hostname
HOSTNAME=$( hostname --short )
#set output directory
OUTPATH="/var/tmp/"
#set the name of the output file
FILENAME=$(echo -n ${OUTPATH}smasGrab.${HOSTNAME}.${TIMESTAMP}.tar )
#set the name of the date file which will contain the date and time that smasGrab.sh was run
DATEFILE=$( echo -n ${TIMESTAMP} )
#set the fully qualified path+name of $DATEFILE
DATEFILEFQ=$( echo -n ${OUTPATH}${TIMESTAMP} )
#set the name of the err file which will contain a list of requested files that do not exist
ERRFILE=$( echo -n smasGrab.${TIMESTAMP}.err )
#set the fully qualifid path+name of $ERRFILE
ERRFILEFQ=$( echo -n ${OUTPATH}smasGrab.${TIMESTAMP}.err )

#set the date into $DATEFILE
echo $( date ) > $DATEFILEFQ
#make sure creating $DATEFILEFQ was successful, if not there is a permission error writing to $OUTPATH
if [ -e $DATEFILEFQ ]
then
	#create the output file
	tar -cf $FILENAME -C $OUTPATH $DATEFILE 2>/dev/null
else
	#warn and exit
	echo "ERROR: unable to create file"  $DATEFILEFQ ".  Please check permissions in" $OUTPATH >&2
	exit
#test to make sure the output file was created
if [ ! -e $FILENAME ] 
then
	#warn and exit
	echo "ERROR: unable to create file" $FILENAME ".  Please check permissions in" $OUTPATH >&2
	exit
fi

#loop on all lines in included files list
for F in $INCLUDEFILES
do
	#check that the requested file exist and is readable
	if [ -r $F ]
	then
		#append the file to the output file
		tar -rf $FILENAME $F 2>/dev/null
	else 
		#warn and exit
		printf "File does not exist or not readable: %s\n" $F >> $ERRFILEFQ
	fi
done

#append the error file to youput file
tar -rf $FILENAME -C $OUTPATH $ERRFILE 2>/dev/null

#cleanup
rm $DATEFILEFQ 2>/dev/null
rm $ERRFILEFQ 2>/dev/null
