#!/bin/bash


snap_install () {
    printf "Installing ${1} ...."
    snap_info_output=$(snap info ${1})
    if [ $? -eq 0 ]
    #TODO if a verbose parameter is given, output snap_info_output
    then
        printf " already installed. \n"
    else
        snap install ${1}
        printf " done\n"
    fi
}


###### MAIN
if [ "$EUID" -ne 0 ];then
    echo "Please run this script as root user or sudo it"
    exit 1
fi


###### ESSENTIALS #######

snap_install chromium

