#!/bin/bash

set -u

SETUP_TEMP_DIR=/tmp/set-laptop-up-files

check_for_flathub_repo () {
    printf "Installing flathub repo .... "
    flathub_matches=$(flatpak remotes | egrep -c '^flathub\s')    
    if [ "$flathub_matches" -eq 0 ]
    then
        printf "\n flathub repo NOT found!\n"
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
        printf "already installed.\n"
    fi
}



flatpak_install () {
    printf "Installing flatpak ${1} .... "
    flatpak_matches=$(flatpak list --app | egrep -c "\s${1}\s")
    if [ "$flatpak_matches" -eq 0 ]
    then
        flatpak install -y flathub ${@}
        printf "done\n"
    else
        printf "already installed.\n"
    fi
}



snap_install () {
    printf "Installing snap ${1} .... "
    snap_info_output=$(snap list ${1})
    if [ $? -eq 0 ]
    #TODO if a verbose parameter is given, output snap_info_output
    then
        printf "already installed.\n"
    else
        snap install ${@}
        printf " done\n"
    fi
}


pkg_install () {
    printf "Installing ${1} .... "
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
    if [ "${install_status}" == "installed" ]
    then
        printf "already installed.\n"
    else
        apt-get -y install ${@}
    fi
}


install_remote_pkg () {
    local temp_file_name=${SETUP_TEMP_DIR}/${1}.deb
    printf "Installing ${1} .... "
    install_status=$(dpkg-query -W --showformat='${db:Status-Status}' ${1} 2>&1)
    if [ "${install_status}" == "installed" ]
    then
        printf "already installed.\n"
    else
	curl ${2} -o ${temp_file_name}
        apt-get -y install ${temp_file_name} 
    fi
    
}

setup_spacemacs () {
    # SUDO_UID, SUDO_GID, SUDO_USER environment variables 
    # are set to the values of the user who runs the 'sudo' command
    # but due to the fact that they are variables that can be overwritten (highly unlikely)
    # I've decided to use the output of the command 'logname'
    
    user_id=$(getent passwd $(logname) | cut -d: -f3)
    grp_id=$(getent passwd $(logname) | cut -d: -f4)
    home_dir=$(getent passwd $(logname) | cut -d: -f6)
    spacemacs_dir="${home_dir}/.emacs.d"

    printf "Installing Spacemacs .... "

    mkdir -p ${spacemacs_dir}
    if [ -z "$(ls -A ${spacemacs_dir})" ]
    then
        printf "${spacemacs_dir} is empty, will git clone Spacemacs into it.\n"
        git clone https://github.com/syl20bnr/spacemacs ${spacemacs_dir}
        # $(cd ${spacemacs_dir} && git checkout develop) 
        chown -R ${user_id}:${grp_id} ${spacemacs_dir}
        printf "Spacemacs cloned into ${spacemacs_dir}\n"
    else
        printf "already installed. ${spacemacs_dir} is NOT empty, won't clone Spacemacs into it\n"
    fi
}

install_clojure () {
    local temp_file_name=${SETUP_TEMP_DIR}/clojure-linux-install.sh
    local clojure_installer_url="https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh"

    printf "Installing latest Clojure .... "
    if [ -e /usr/local/bin/clj ] || [ -e /usr/local/bin/clojure ]
    then
        printf "already installed.\n"
    else
        curl -L ${clojure_installer_url} -o ${temp_file_name} 
        chmod +x ${temp_file_name}
	source ${temp_file_name}
    fi
}



###### MAIN
if [ "$EUID" -ne 0 ]
then
    echo "Please run this script as root user or sudo it"
    exit 1
fi

###### SETUP ######
apt update
mkdir -p ${SETUP_TEMP_DIR}




###### CORE ######
pkg_install openssh-server

pkg_install flatpak
pkg_install gnome-software-plugin-flatpak
check_for_flathub_repo

pkg_install zsh
pkg_install curl
pkg_install tree



###### ESSENTIALS #######
pkg_install vlc
pkg_install gnome-tweaks                             # For remapping keys under Gnome
snap_install chromium
snap_install brave
snap_install slack
snap_install spotify
snap_install discord
# flatpak_install org.keepassxc.KeePassXC




###### DEVELOPMENT #######
pkg_install direnv
pkg_install git
pkg_install openjdk-17-jdk-headless
pkg_install rlwrap                                    # For clojure clj tool
install_clojure
pkg_install python3
pkg_install python3-pip

snap_install emacs --classic
setup_spacemacs

snap_install nvim --classic
install_remote_pkg keybase https://prerelease.keybase.io/keybase_amd64.deb

snap_install postman
snap_install code --classic
snap_install intellij-idea-community --classic
snap_install pycharm-community --classic



###### CLEANUP  ######
rm -rf ${SETUP_TEMP_DIR}
