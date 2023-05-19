#!/bin/sh

#/** \attention
#*
#*  RBEI Copyright 2017-2021 RBEI All Rights Reserved.
#*
#*/
# CONFIG_MAPPER=config-alias
# CONFIG_DEVICE=/dev/mmcblk0p3
# CONFIG_DIR=/config


SuccessMsg="Success"
FailureMsg="Failure"
LogOnlyMsg="LogOnly"

PASSPHASE=$(cat /proc/sys/kernel/random/uuid | sed 's/[-]//g')
echo "$PASSPHASE"

fw_setenv passphase $PASSPHASE
fw_setenv config_part 0

encryptPartition()
{
	
    CONFIG_DEVICE=$1
	CONFIG_DIR=$2
	CONFIG_MAPPER=$3

	if [ "$#" -ne 3 ] 
	then
		logger "Error: Incorrect number of arguments passed to the function"
		return 1
	fi

	if [ $CONFIG_DIR == /config ]
	then 
		cp -rf $CONFIG_DIR /tmp/
	fi
	umount $CONFIG_DIR
	#fw_printenv
	echo -n $PASSPHASE | cryptsetup luksFormat  $CONFIG_DEVICE --batch-mode 2> /dev/null
	echo -n $PASSPHASE | cryptsetup luksAddKey $CONFIG_DEVICE  2> /dev/null
	echo -n $PASSPHASE | cryptsetup luksOpen $CONFIG_DEVICE $CONFIG_MAPPER 2> /dev/null

	if [ $? == 0 ]
	then
		mkfs.ext4 -q /dev/mapper/$CONFIG_MAPPER 2> /dev/null
		if [ $? == 0 ]
		then
				if [ -d $CONFIG_DIR ]
				then
					rm -rf $CONFIG_DIR
					mkdir $CONFIG_DIR
				else
					mkdir $CONFIG_DIR
				fi

				mount /dev/mapper/$CONFIG_MAPPER $CONFIG_DIR 2> /dev/null
				sleep 5
				Mountpoint=$(df -P /config | tail -1 | cut -d' ' -f 1 )
				if [ ${Mountpoint} = "/dev/mapper/$CONFIG_MAPPER" ]
				then
					if [ $CONFIG_DIR == /config ]
					then 
						cp -rf /tmp/config/* /config/
					fi					
					logger "$SuccessMsg" "Encryption is successful" "NA"
					return 0

				else
					logger "The Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
					return 1
				fi
		else
				logger "The Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
				return 1
		fi
	else
		logger "The Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
		return 1
	fi
}


#encrypt emmc config partition memory
DEVICE=/dev/mmcblk0p3
DIR=/config
MAPPER=config-alias

encryptPartition $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
    logger "The Emmc Config Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
else
    fw_setenv config_part 1 2>&1
fi

#encrypt SD card partition 1
DEVICE=/dev/mmcblk1p1
DIR=/home/vivascope_developer/VivascopeConnectedHealth/logs
MAPPER=sdcard-log-alias

encryptPartition $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
    logger "The SD card partition 1 Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
else
    fw_setenv config_part 2 2>&1
fi


#encrypt SD card partition 2
DEVICE=/dev/mmcblk1p2
DIR=/home/vivascope_developer/VivascopeConnectedHealth/testResults
MAPPER=sdcard-data-alias

encryptPartition $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
    logger "The SD card partition 2 Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
else
    fw_setenv config_part 3 2>&1
fi

#encrypt SD card partition 3
DEVICE=/dev/mmcblk1p3
DIR=/download
MAPPER=sdcard-download-alias

encryptPartition $DEVICE $DIR $MAPPER
return_value=$?
if [ $return_value != 0 ] 
then 
    logger "The SD card partition 3 Encryption is Failed , Please re-format and flash the image to restart the test" "NA"
else
    fw_setenv config_part 4 2>&1
fi


echo "Return value: $?"