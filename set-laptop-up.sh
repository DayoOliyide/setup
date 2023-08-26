#!/bin/bash

check_for_flathub_repo () {
    printf "Checking that flathub repo has been added ...."
    flathub_matches=$(flatpak remotes | egrep -c '^flathub\s')    
    if [ "$flathub_matches" -eq 0 ]
    then
        printf " flathub repo NOT found!\n"
        printf "Adding flathub repo .....\n"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        if [ $? -ne 0 ]
        then
            printf "Adding flathub repo has failed!!! Exiting script!\n"
            exit 2
        fi
        printf "flathub repo added\n"
        printf "For flathub repo to be picked and used in flatpak later installs, System reboot required now\n" 
        read -p "REBOOT SYSTEM ? (y/n) " should_reboot
        if [ "$should_reboot" = "y" ]
        then
            shutdown -r now 
        else
            printf "################################################################\n"
            printf "Exiting setup script as reboot needed for any flatpak installs!!\n"
            printf "Please reboot system before running this script again!!!\n"
            printf "################################################################\n"
            exit 3
        fi
    else
        printf " flathub repo found\n"
    fi
}



flatpak_install () {
    printf "Installing flatpak ${1} ...."
    flatpak_matches=$(flatpak list --app | egrep -c "\s${1}\s")
    if [ "$flatpak_matches" -eq 0 ]
    then
        flatpak install -y flathub ${1}
        printf " done\n"
    else
        printf " already installed. \n"
    fi
}



snap_install () {
    printf "Installing snap ${1} ...."
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


###### CORE ######
pkg_install openssh-server

pkg_install flatpak
pkg_install gnome-software-plugin-flatpak
check_for_flathub_repo

pkg_install zsh
pkg_install curl

###### ESSENTIALS #######
snap_install chromium
snap_install brave
flatpak_install org.keepassxc.KeePassXC


###### DEVELOPMENT #######

pkg_install git
