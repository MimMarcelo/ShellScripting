#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/

###############################################################################
# Definição das variáveis                                                     #
PROGRAMS_TO_UNINSTALL=(
    libreoffice
    gimp
)
APT_PROGRAMS=(
    inkscape
    kdenlive breeze frei0r-plugins
    mysql-workbench
    mysql-server
    php php-curl php-mbstring php-mysql php-sqlite3
)

FLATPAK_PROGRAMS=(
    com.google.AndroidStudio
    com.obsproject.Studio
    org.apache.netbeans
    org.audacityteam.Audacity
    org.gimp.GIMP
    org.inkscape.Inkscape
    com.getpostman.Postman
    com.spotify.Client
    org.stellarium.Stellarium
    com.sweethome3d.Sweethome3d
    org.videolan.VLC
    org.libreoffice.LibreOffice
)

PPAs=(
    ppa:ondrej/php
    ppa:graphics-drivers/ppa
    ppa:kdenlive/kdenlive-stable
)

URLs=(
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    https://d2t3ff60b2tol4.cloudfront.net/builds/insync_3.0.20.40428-bionic_amd64.deb
    https://download.virtualbox.org/virtualbox/6.1.8/virtualbox-6.1_6.1.8-137981~Ubuntu~eoan_amd64.deb
    https://download.virtualbox.org/virtualbox/6.1.8/Oracle_VM_VirtualBox_Extension_Pack-6.1.8.vbox-extpack
    http://staruml.io/download/releases/StarUML-3.2.2.AppImage
)

DOWNLOADS="$HOME/Downloads/programs"
APPIMAGE_PATH="$HOME/.AppImage"

###############################################################################
# Removendo eventuais travas do APT                                           #
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

echo "************************************************************************"
echo "* UNINSTALL SOME PREINSTALLED PROGRAMS                                 *"
echo "************************************************************************"
for program in ${PROGRAMS_TO_UNINSTALL[@]}; do
    sudo apt remove --purge $program* -y
done

###############################################################################
# Limpa o cache das desinstalações                                            #
sudo apt clean
sudo apt autoremove -y

echo "************************************************************************"
echo "* PPAs REGISTER                                                        *"
echo "************************************************************************"
for ppa in ${PPAs[@]}; do
    sudo apt-add-repository "$ppa" -y
done

###############################################################################
# Atualização das dependências do sistema                                     #
sudo apt update -y

echo "************************************************************************"
echo "* INSTALL APT PROGRAMS                                                 *"
echo "************************************************************************"
for program in ${APT_PROGRAMS[@]}; do
    apt install $program -y
done

echo "************************************************************************"
echo "* INSTALL FLATPAK PROGRAMS                                             *"
echo "************************************************************************"
flatpak update
for program in ${FLATPAK_PROGRAMS[@]}; do
    flatpak install flathub $program -y
done

echo "************************************************************************"
echo "* DOWNLOAD PROGRAMS                                                    *"
echo "************************************************************************"
mkdir $DOWNLOADS
for url in ${URLs[@]}; do
    wget -c "$url" -P "$DOWNLOADS"
done

echo "************************************************************************"
echo "* INSTALL DEB PROGRAMS                                                 *"
echo "************************************************************************"
debs=$(find $DOWNLOADS -type f -iregex ".*\.\(deb\)")
for deb in $debs; do
    sudo dpkg -i $deb
done

echo "************************************************************************"
echo "* COPYING APPIMAGE PROGRAMS                                            *"
echo "************************************************************************"
appImages=$(find $DOWNLOADS -type f -iregex ".*\.\(appimage\)")
if [ -z $appImages ]; then
    echo "None AppImage to Install"
else
    mkdir $APPIMAGE_PATH
    for appImage in $appImages; do
        cp "$appImage" "$APPIMAGE_PATH/"
    done
fi

echo "************************************************************************"
echo "* UPDATE, CLEAN AND ENDING                                             *"
echo "************************************************************************"
sudo apt update
sudo apt upgrade -y
sudo apt autoclean
sudo apt autoremove -y
