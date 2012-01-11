#!/usr/bin/ksh

#Gather port WWNs for all HBAs

#test for the correct version of Solaris
if [ ! "5.9" = $(uname -a) -o ! "SunOS" -eq $(uname) ]
then
	echo "This script only works with Solaris 9.  Sorry." >&2
	exit
fi

HBACOUNT=0
for ihba in `cfgadm | grep "fc-fabric" | awk '{print $1}'` ; do
dev=`cfgadm -lv $ihba | grep "devices" | awk '{print $NF}'`
wwns[$HBACOUNT]=`luxadm -e dump_map $dev | grep "Host Bus" | awk '{print $4}'`
HBACOUNT=$(( $HBACOUNT + 1 ))
done

if (( $HBACOUNT < 2 )) ; then
echo "WARNING: This host does not have enough unique HBAs to have fully redundant paths."
fi


echo "${#wwns[*]} HBAs discovered. WWNs: ${wwns[*]}"
#echo "${wwns[*]}"

mperror=0


for idisk in `luxadm probe | grep "Logical Path" | grep -v "rmt" | grep -v "Node" | awk -F":" '{print $2}'` ; do

echo "================================================================================================"
npathsonline=`luxadm display $idisk | grep "ONLINE" | wc -l`
npathsstandby=`luxadm display $idisk | grep "STANDBY" | wc -l`
npathtype=`luxadm display $idisk | grep "Product ID" | awk -F":" '{print $2}'`
npaths=$(($npathsonline + $npathsstandby))

if (( $npaths == 1 )) ; then
echo "WARNING:  `basename $idisk` had only 1 path"
if (( $mperror == 0 )) || [[ ${amperror[$(( $mperror - 1 ))]} != `basename $idisk` ]]; then
amperror[$mperror]=`basename $idisk`
mperror=$(( $mperror + 1))
#else condition is the error has already been noted and we don't need to report it again
fi
fi

if (( $npathsonline != $npaths )) ; then
echo " NOTE: Standby Path Detected. "
echo $idisk : $npathtype : $npathsonline "of" $npaths "path(s) active."
else
echo $idisk : $npathtype : $npaths "path(s) found."
fi


for wwn in ${wwns[*]} ; do
wwnpathsonline=`luxadm display $idisk | sed -e's/Controller/\%Controller/' | awk 'BEGIN {FS="\n" ; RS="%" } {print $2 $3 $4 $5}' | awk ' {print $3 " : " $8 " : " $10 " : " $12}' | grep -v "Product" | grep "ONLINE" | grep $wwn | wc -l`
wwnpathsstandby=`luxadm display $idisk | sed -e's/Controller/\%Controller/' | awk 'BEGIN {FS="\n" ; RS="%" } {print $2 $3 $4 $5}' | awk ' {print $3 " : " $8 " : " $10 " : " $12}' | grep -v "Product"| grep "STANDBY" | grep $wwn | wc -l`
wwnpaths=$(($wwnpathsonline + $wwnpathsstandby))
if (( $wwnpaths < 1 )) ; then
echo "> ! ERROR: HBA" $wwn "has" $wwnpaths "paths to device `basename $idisk`. ! <"


if (( $mperror == 0 )) || [[ ${amperror[$(( $mperror - 1 ))]} != `basename $idisk` ]]; then
amperror[$mperror]=`basename $idisk`
mperror=$(( $mperror + 1))
#else condition is the error has already been noted and we don't need to report it again
fi

fi
echo "$wwnpaths path(s) found on HBA" $wwn"." $wwnpathsonline "active and" $wwnpathsstandby "standby"
done

done
echo ""
echo "################################################################################################"
echo " MPxIO multipathing check complete. "
if (( $mperror > 0 )) ; then
echo "    $mperror ERRORS found! The following devices may not be multipathed: "
echo "${amperror[*]}"
if (( $HBACOUNT < 2 )) ; then
echo "    WARNING: This host does not have enough unique HBAs to have fully redundant paths."
fi
elif (( $HBACOUNT < 2 )) ; then
echo "    WARNING: This host does not have enough unique HBAs to have fully redundant paths."
else
echo " No Errors Found"
fi
echo "################################################################################################"
echo ""
echo ""


#luxadm display $idisk | sed -e's/Controller/\%Controller/' | awk 'BEGIN {FS="\n" ; RS="%" } {print $2 $3 $4 $5}' | awk '{print $3 " : " $8 " : " $10 " : " $12}' | grep -v "Product"
