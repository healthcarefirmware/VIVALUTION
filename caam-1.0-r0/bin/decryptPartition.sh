#!/bin/sh

#/** \attention
#*
#*  RBEI Copyright 2017-2021 RBEI All Rights Reserved.
#*
#*/
# CONFIG_MAPPER=config-alias
# CONFIG_DEVICE=/dev/mmcblk0p3
# CONFIG_DIR=/config

PASSPHASE=$(fw_printenv passphase 2>&1 | awk -F"=" '/passphase/{print $2}' 2>&1)
ConfigPart=$(fw_printenv config_part 2>&1 | awk -F "=" '/config_part/{print $2}' 2>&1)

MountConfig()
{
   
    CONFIG_DEVICE=$1
	CONFIG_DIR=$2
	CONFIG_MAPPER=$3

	if [ "$#" -ne 3 ] 
	then
		logger "Error: Incorrect number of arguments passed to the function"
		return 1
	fi

    if [ "$ConfigPart"  != "0" ] 
    then

        echo -n $PASSPHASE | cryptsetup luksOpen $CONFIG_DEVICE $CONFIG_MAPPER
        sleep 2
        mount /dev/mapper/$CONFIG_MAPPER $CONFIG_DIR
    	sleep 5 
    	Mountpoint=$(df -P $CONFIG_DIR | tail -1 | cut -d' ' -f 1 )
    	printf "$Mountpoint\n"
    	if [ ${Mountpoint} = "/dev/mapper/$CONFIG_MAPPER" ]
    	then
			logger " $Mountpoint" "$SuccessMsg" "decryption is successful" "NA"
       		return 0
    	else
       		logger "The mount of config partition is failed \n "
       		return 1 
    	fi 
    else 
	    mount $CONFIG_DEVICE $CONFIG_DIR
		logger "$CONFIG_DEVICE" "is Mounted Normally \n "
		return 0
    fi
}

# filename="/tmp/FIFO"

# if [ "$(cat $filename)" == "complete" ]
# then
#   echo "EOL is Done "

# else
#   echo "Device is in EOL Mode"
# fi


#decrypt emmc config partition memory
DEVICE=/dev/mmcblk0p3
DIR=/config
MAPPER=config-alias

MountConfig $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
	logger "$CONFIG_DEVICE" "The mount partition is failed"
fi



#decrypt SD card partition 1
DEVICE=/dev/mmcblk1p1
DIR=/home/vivascope_developer/VivascopeConnectedHealth/logs
MAPPER=sdcard-log-alias

MountConfig $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
	logger  "$CONFIG_DEVICE" "The mount partition is failed"
fi



#decrypt SD card partition 2
DEVICE=/dev/mmcblk1p2
DIR=/home/vivascope_developer/VivascopeConnectedHealth/testResults
MAPPER=sdcard-data-alias

MountConfig $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
	logger "$CONFIG_DEVICE" "The mount partition is failed"
fi



#decrypt SD card partition 3
DEVICE=/dev/mmcblk1p3
DIR=/download
MAPPER=sdcard-download-alias

MountConfig $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
	logger "$CONFIG_DEVICE" "The mount partition is failed"
fi

echo "Return value: $?"