#!/usr/bin/ksh93

#
# PowerVM Multi-vSCSI Path Balancing Script
# by: Joe M. Searcy
# email: jmsearcy@us.ibm.com
#
# 
# This script is used to dynamically balance hdisk path priority across multiple vSCSI adapters
# for all disks within a system.
#
# This was developed for customers who have vSCSI disks federated across multiple vSCSI adapters
# for improved performance.
#
#       v1.0 -> 
#               01-18-2013 - Joe Searcy -> Initial script
#               01-18-2013 - Joe Searcy -> Added filter for non-vSCSI disks
#               01-18-2013 - Joe Searcy -> Added logic for single path vSCSI disks
#  	        01-25-2013 - Joe Searcy -> Fixed vSCSI count array arithmetic
#               01-27-2013 - Joe Searcy -> Added some additional comments and configured to 
#                                          perform changes instead of only echoing to stdout
#

#### Variables ####

DISKLIST=`cat disk_list.out | awk '{ print $1 }'`
VSCSILIST=`cat /tmp/gp_vscsi_balance/lspath.out | awk '{ print $3 }' | sed s/vscsi//`


#### Create Arrays ####

typeset -a vscsiCountArray
typeset -A path1Array
typeset -A path2Array


#### Build vscsiCountArray ####

        for vscsi in $VSCSILIST

                do
        
                        vscsiCountArray[$vscsi]=0
                
        done


#### Build path1Array ####

        for hdisk in $DISKLIST

                do
        
                        PATH1=`cat /tmp/gp_vscsi_balance/lspath.out | grep "$hdisk " | head -1 | awk '{ print $3 }' | sed s/vscsi//`
                        path1Array[$hdisk]=$PATH1
                
        done


#### Build path2Array ####

        for hdisk in $DISKLIST

                do
                        
                        PATH2=`cat /tmp/gp_vscsi_balance/lspath.out | grep  "$hdisk " | tail -1 | awk '{ print $3 }' | sed s/vscsi//`
                        path2Array[$hdisk]=$PATH2
                
        done

        
#### Main Loop to set path priority per hdisk ####

        for hdisk in $DISKLIST

                do
        
                        PATH1=${path1Array[$hdisk]}
                        PATH2=${path2Array[$hdisk]}
                        
                        if [ $PATH1 == $PATH2 ]
                        
                                then
                                
                                        echo
                                        echo "Disk \"$hdisk\" does not have multiple paths"
                                        
                                        echo
                                        echo "#######################################################"
                                        echo
                                        
                        else
                
                                        # Compare Path 1 count to Path 2 count and set priority
                
                                        if [ ${vscsiCountArray[$PATH1]} == ${vscsiCountArray[$PATH2]} ]
                
                                                then
                                        
                                                        echo
                                                        echo "$hdisk uses \"vscsi${path1Array[$hdisk]}\" & \"vscsi${path2Array[$hdisk]}\""
                                                        
                                                        #### Begin DEBUG ####
                                                        #echo "Path 1 count: ${vscsiCountArray[$PATH1]}"
                                                        #echo "Path 2 count: ${vscsiCountArray[$PATH2]}"
                                                        #echo
                                                        #echo "chpath -l $hdisk -p vscsi$PATH1 -a priority=1"
                                                        #echo "chpath -l $hdisk -p vscsi$PATH2 -a priority=2"
                                                        #### End DEBUG ####

                                                        echo
                                                        
                                                        # Actually change path priority (comment out for DEBUG)

                                                        chpath -l $hdisk -p vscsi$PATH1 -a priority=1
                                                        chpath -l $hdisk -p vscsi$PATH1 -a priority=2
                                
                                                        ((vscsiCountArray[$PATH1]+=1))
                                        
                                                        #### Begin DEBUG ####
                                                        #echo "Path 1 count: ${vscsiCountArray[$PATH1]}"
                                                        #echo "Path 2 count: ${vscsiCountArray[$PATH2]}"
                                                        #### End DEBUG ####

                                        
                                                        echo                    
                                                        echo "#######################################################"
                                                        echo
                                
                                        else
                
                                                        echo
                                                        echo "$hdisk uses \"vscsi${path1Array[$hdisk]}\" & \"vscsi${path2Array[$hdisk]}\""
                                                        
                                                        #### Begin DEBUG ####
                                                        #echo "Path 1 count: ${vscsiCountArray[$PATH1]}"
                                                        #echo "Path 2 count: ${vscsiCountArray[$PATH2]}"
                                                        #echo
                                                        #echo "chpath -l $hdisk -p vscsi$PATH1 -a priority=2"
                                                        #echo "chpath -l $hdisk -p vscsi$PATH2 -a priority=1"
                                                        #### End DEBUG ####

                                                        echo

                                                        # Actually change path priority (comment out for DEBUG)

                                                        echo "chpath -l $hdisk -p vscsi$PATH1 -a priority=2"
                                                        echo "chpath -l $hdisk -p vscsi$PATH2 -a priority=1"
                                
                                                        ((vscsiCountArray[$PATH2]+=1))
                                        
                                                        #### Begin DEBUG ####
                                                        #echo "Path 1 count: ${vscsiCountArray[$PATH1]}"
                                                        #echo "Path 2 count: ${vscsiCountArray[$PATH2]}"
                                                        #### End DEBUG ####
                                        
                                                        echo
                                                        echo "#######################################################"
                                                        echo
                                
                                        fi
                                        
                        fi
                
        done
