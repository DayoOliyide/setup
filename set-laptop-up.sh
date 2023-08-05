#!/bin/bash


snap_install () {
    printf "Installing ${1} ...."
    snap_info_output=$(snap list ${1})
    if [ $? -eq 0 ]
    #TODO if a verbose parameter is given, output snap_info_output
    then
        printf " already installed. \n"
    else
        snap install ${1}
        printf " done\n"
    fi
}


pkg_install () {
    printf "Installing ${1} ...."
    install_status=$(dpkg-query -W --showformat='${db:Status-Status}' ${1} 2>&1)
    #NOTE
    # The $? = 0 check could needed because if you've never installed a package
    # before, and after you remove certain packages such as hello, dpkg-query 
    # exits with status 1 and outputs to stderr:
    #
    # "dpkg-query: no packages found matching hello"
    #
    # instead of outputting not-installed. The 2>&1 captures that error message
    # too when it comes preventing it from going to the terminal.
    # FOR NOW NOT CHECKING $? = 0  BUT GOOD TO KNOW FOR FUTURE 
    if [ $install_status = "installed" ]
    then
        printf " already installed. \n"
    else
        apt-get -y install ${1}
    fi
}


###### MAIN
if [ "$EUID" -ne 0 ];then
    echo "Please run this script as root user or sudo it"
    exit 1
fi


###### TOOLS ######
pkg_install openssh-server


###### ESSENTIALS #######

snap_install chromium
snap_install brave



###### DEVELOPMENT #######

pkg_install git
