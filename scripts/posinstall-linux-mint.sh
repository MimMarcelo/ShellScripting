#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/ShellScripting

###############################################################################
# Verifica se o script está sendo executado como sudo                         #
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

###############################################################################
# Definição das variáveis                                                     #
PROGRAMS_TO_UNINSTALL=(
    libreoffice
    gimp
    inkscape
    memtest86+
)
APT_PROGRAMS=(
    software-properties-common 
    kdenlive breeze frei0r-plugins
    mysql-workbench
    mysql-server
    php php-curl php-mbstring php-mysql php-pdo php-sqlite3 phpunit
    git
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

GIT_EMAIL="rokermarcelo@gmail.com"
GIT_USER="Marcelo Júnior"

MYSQL_ROOT_PASSWORD="Senha12#"

DOWNLOADS="$HOME/Downloads/programs"
APPIMAGE_PATH="$HOME/.AppImage"
GRUB="/etc/default/grub"

if [ ! -d "$DOWNLOADS" ]; then
    mkdir "$DOWNLOADS"
fi

if [ ! -d "$APPIMAGE_PATH" ]; then
    mkdir "$APPIMAGE_PATH"
fi

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
apt install ${APT_PROGRAMS[@]} -y

echo "************************************************************************"
echo "* INSTALL FLATPAK PROGRAMS                                             *"
echo "************************************************************************"
flatpak update
flatpak install flathub ${FLATPAK_PROGRAMS[@]} -y

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
echo "* INSTALL COMPOSER                                                     *"
echo "************************************************************************"
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    echo "Composer installation failed"
fi

php composer-setup.php --install-dir=$DONWLOADS --quiet
RESULT=$?
rm composer-setup.php
mv "$DOWNLOADS/composer.phar" /usr/local/bin/composer

echo "************************************************************************"
echo "* GIT CONFIGURATION                                                    *"
echo "************************************************************************"
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

echo "************************************************************************"
echo "* MYSQL CONFIGURATION                                                  *"
echo "************************************************************************"
if [ $(dpkg-query -W -f='${Status}' expect 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Can't find expect. Trying install it..."
    aptitude -y install expect
fi

SECURE_MYSQL=$(expect -c "
    set timeout 3
    spawn mysql_secure_installation
    expect \"Press y|Y for Yes, any other key for No:\"
    send \"y\r\"
    expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
    send \"2\r\"
    expect \"New password:\"
    send \"$MYSQL_ROOT_PASSWORD\r\"
    expect \"Re-enter new password:\"
    send \"$MYSQL_ROOT_PASSWORD\r\"
    expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
    send \"y\r\"
    expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
    send \"y\r\"
    expect \"RDisallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
    send \"y\r\"
    expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
    send \"y\r\"
    expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
    send \"y\r\"
    expect eof
")

#
# Execution mysql_secure_installation
#
echo "${SECURE_MYSQL}"

ENABLE_ROOT_BY_PASSWORD=$(expect -c "
    set timeout 3
    spawn mysql
    send \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';\r\"
    send \"FLUSH PRIVILEGES;\r\"
    send \"exit;\r\"
    expect eof
")

echo "${ENABLE_ROOT_BY_PASSWORD}"

aptitude -y purge expect

echo "************************************************************************"
echo "* GRUB CONFIGURATION                                                   *"
echo "************************************************************************"
sed -e "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/" -e "s/#GRUB_DISABLE_RECOVERY=.*/GRUB_DISABLE_RECOVERY=\"true\"\nGRUB_DISABLE_SUBMENU=\"y\"/" "$GRUB" >"$DOWNLOADS/grub"
sudo cp "$GRUB" "$GRUB.original"
sudo mv "$DOWNLOADS/grub" "$GRUB"
sudo update-grub

echo "************************************************************************"
echo "* UPDATE, CLEAN AND ENDING                                             *"
echo "************************************************************************"
sudo apt update
sudo apt upgrade -y
sudo apt autoclean
sudo apt autoremove -y
