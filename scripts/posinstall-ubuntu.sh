#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/ShellScripting

###############################################################################
# Verifica se o script está sendo executado como sudo                         #
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

###############################################################################
# Define as variáveis                                                         #
spin='-\|/' # Utilizado na função [loading], representa o carregamento

GIT_EMAIL="rokermarcelo@gmail.com"   # e-mail global do Git
GIT_USER="Marcelo Júnior"            # Usuário global do Git

MYSQL_ROOT_PASSWORD="Senha12#"       # Senha de root do MySQL

# Utilizar [$HOME] aponta para o home do root,
# já que o script é executado como tal
DOWNLOADS="/home/marcelo/Downloads/programs" # Pasta onde os baixar os programas

# Apenas para quando em Dualboot
# GRUB="/etc/default/grub"             # Localização do GRUB do sistema

###############################################################################
# Define as listas                                                            #
PROGRAMS_TO_UNINSTALL=(
    libreoffice-core
    gimp
    inkscape
    memtest86+
    celluloid
    gnote
    redshift
    rhythmbox
)
APT_PROGRAMS=(
    software-properties-common
    gnome-tweak-tool
    gnome-shell-extensions
    numix-blue-gtk-theme
    nemo nemo-python nemo-fileroller nemo-data
    breeze frei0r-plugins
    mysql-server
    php php-curl php-mbstring php-mysql php-sqlite3 phpunit
    git
    libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386
    ttf-mscorefonts-installer
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
    org.kde.kdenlive
    io.atom.Atom
)

PPAs=(
    ppa:ondrej/php
    ppa:graphics-drivers/ppa
)

URLs=(
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    https://d2t3ff60b2tol4.cloudfront.net/builds/insync_3.0.20.40428-bionic_amd64.deb
    https://download.virtualbox.org/virtualbox/6.1.8/virtualbox-6.1_6.1.8-137981~Ubuntu~eoan_amd64.deb
    https://download.virtualbox.org/virtualbox/6.1.8/Oracle_VM_VirtualBox_Extension_Pack-6.1.8.vbox-extpack
    http://cdn.mysql.com/Downloads/MySQLGUITools/mysql-workbench-community_8.0.20-1ubuntu20.04_amd64.deb
)

###############################################################################
# Define as funções                                                           #

# Exibe elemento alusivo ao carregamento do processo
# Recebe por parâmetro [$!] do processo
function loading {
  i=0
  while kill -0 $1 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r- Loading [${spin:$i:1}]"
    sleep .1
  done
}

# Instala programa Flatpak
# Recebe por parâmetro [nome_de_instalação] Flatpak
function installFlatpak {
  echo "Program $1:"
  status=$(flatpak install flathub $1 -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not installed         \n"
  else
      printf "\r- Installed             \n"
  fi
}

# Instala programa Apt
# Recebe por parâmetro [nome_de_instalação] apt
function installApt {
  echo "Program $1:"
  status=$(apt install $1 -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not installed         \n"
  else
      printf "\r- Installed             \n"
  fi
}

# Instala programa .deb baixado
# Recebe por parâmetro [nome_de_instalação] .deb
function installDeb {
  echo "Program $1:"
  status=$(dpkg -i $deb 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not installed         \n"
  else
      printf "\r- Installed             \n"
  fi
}

# Desinstala programa Apt
# Recebe por parâmetro [nome_de_desinstalação] apt
function uninstallApt {
  echo "Program $1:"
  if dpkg -l | grep -q $1; then # Só desinstala se estiver instalado
      status=$(apt remove --purge $1 -y 2> /dev/null) &
      loading $! # Envia o [id do processo] para a função de loading

      if [ $status > 0 ]; then
          printf "\r- Not uninstalled         \n"
      else
          printf "\r- Uninstalled             \n"
      fi
  else
      echo "- Program not found           "
  fi
}

# Adiciona PPA
# Recebe por parâmetro [nome] do PPA
function addPPA {
  echo "PPA $1:"
  status=$(apt-add-repository "$1" -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not added         \n"
  else
      printf "\r- Added             \n"
  fi
}

# Baixa programa
# Recebe por parâmetro [url] do programa
function downloadProgram {
  echo "Download $1:"
  status=$(wget -c "$url" -P "$DOWNLOADS" 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not downloaded       \n"
  else
      printf "\r- Downloaded           \n"
  fi
}

echo "************************************************************************"
echo "* PREREQUISITS                                                         *"
echo "************************************************************************"
###############################################################################
# Cria diretórios importantes para o processo                                 #
echo "Making important directories"
if [ ! -d "$DOWNLOADS" ]; then
    echo "- $DOWNLOADS"
    mkdir "$DOWNLOADS"
fi

# if [ ! -d "$APPIMAGE_PATH" ]; then
#     mkdir "$APPIMAGE_PATH"
# fi
echo "- Ready"

###############################################################################
# Remove eventuais travas do APT                                              #
echo "Making APT free"
rm /var/lib/dpkg/lock-frontend
rm /var/cache/apt/archives/lock
echo "- Ready"

echo "************************************************************************"
echo "* UNINSTALL SOME PREINSTALLED PROGRAMS                                 *"
echo "************************************************************************"
for program in ${PROGRAMS_TO_UNINSTALL[@]}; do
    uninstallApt $program
done

###############################################################################
# Limpa o cache das desinstalações                                            #
echo "Cleaning cache"
apt clean
apt autoremove -y
echo "Ready"

echo "************************************************************************"
echo "* PPAs REGISTER                                                        *"
echo "************************************************************************"
for ppa in ${PPAs[@]}; do
    addPPA $ppa
done

###############################################################################
# Atualização das dependências do sistema                                     #
echo "************************************************************************"
echo "* UPDATING SYSTEM DEPENCENCIES                                         *"
echo "************************************************************************"
echo "APT dependencies"
status=$(apt update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
    printf "\r- Not updated          \n"
else
    printf "\r- Updated              \n"
fi

echo "Flatpak dependencies"
status=$(flatpak update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
    printf "\r- Not updated          \n"
else
    printf "\r- Updated              \n"
fi

###############################################################################
# Aceita os termos de instalação das fontes da Microsoft                      #
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

echo "************************************************************************"
echo "* INSTALL APT PROGRAMS                                                 *"
echo "************************************************************************"
for program in ${APT_PROGRAMS[@]}; do
    installApt $program
done


echo "************************************************************************"
echo "* INSTALL FLATPAK PROGRAMS                                             *"
echo "************************************************************************"
for program in ${FLATPAK_PROGRAMS[@]}; do
    installFlatpak $program
done

echo "************************************************************************"
echo "* DOWNLOAD PROGRAMS                                                    *"
echo "************************************************************************"
mkdir $DOWNLOADS
for url in ${URLs[@]}; do
    downloadProgram $url
done

echo "************************************************************************"
echo "* INSTALL DEB PROGRAMS                                                 *"
echo "************************************************************************"
debs=$(find $DOWNLOADS -type f -iregex ".*\.\(deb\)")
for deb in $debs; do
    installDeb $deb
done

echo "************************************************************************"
echo "* REPLACE NAUTILUS WITH NEMO                                           *"
echo "************************************************************************"
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
sudo apt-get remove --auto-remove nautilus nautilus*

echo "************************************************************************"
echo "* INSTALL COMPOSER                                                     *"
echo "************************************************************************"
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
echo "Downloading..."
status=$(php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" 2> /dev/null) &
loading $!

if [ $status > 0 ]; then
  printf "\r- Download failed          \n"
else
  printf "\r- Download complete        \n"
fi

ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

echo "Validating checksum..."
if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    >&2 echo "- Invalid"
    rm composer-setup.php
    exit 1
else
    echo "- Ok"
fi

echo "Making installer..."
status=$(php composer-setup.php --quiet 2> /dev/null) &
loading $!

if [ $status > 0 ]; then
  printf "\r- Operation failed          \n"
else
  printf "\r- Operation complete        \n"
fi
rm composer-setup.php

status=$(mv composer.phar /usr/local/bin/composer 2> /dev/null)

if [ $status > 0 ]; then
  printf "\r- Not installed globally    \n"
else
  printf "\r- installed globally        \n"
fi

echo "************************************************************************"
echo "* GIT CONFIGURATION                                                    *"
echo "************************************************************************"
echo "Setting global user and e-mail"
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"
echo "- Ready"

echo "************************************************************************"
echo "* MYSQL CONFIGURATION                                                  *"
echo "************************************************************************"
if [ $(dpkg-query -W -f='${Status}' expect 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing expect..."
    status=$(aptitude -y install expect 2> /dev/null) &
    loading $! # Envia o [id do processo] para a função de loading

    if [ $status > 0 ]; then
      printf "\r- Not installed         \n"
    else
      printf "\r- Installed             \n"
    fi
fi
echo "Running mysql_secure_installation..."
#
# Execution mysql_secure_installation
#
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
echo "- Ready"
# echo "${SECURE_MYSQL}"
echo "Setting root access..."
ENABLE_ROOT_BY_PASSWORD=$(expect -c "
    set timeout 3
    spawn mysql
    send \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';\r\"
    send \"FLUSH PRIVILEGES;\r\"
    send \"exit;\r\"
    expect eof
")

# echo "${ENABLE_ROOT_BY_PASSWORD}"
echo "- Ready"
echo "Removing expect..."
status=$(aptitude -y purge expect 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not uninstalled         \n"
else
  printf "\r- Uninstalled             \n"
fi

echo "************************************************************************"
echo "* GRUB CONFIGURATION                                                   *"
echo "************************************************************************"
sed -e "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/" -e "s/#GRUB_DISABLE_RECOVERY=.*/GRUB_DISABLE_RECOVERY=\"true\"\nGRUB_DISABLE_SUBMENU=\"y\"/" "$GRUB" >"$DOWNLOADS/grub"
cp "$GRUB" "$GRUB.original"
mv "$DOWNLOADS/grub" "$GRUB"
update-grub

echo "************************************************************************"
echo "* UPGRADE, CLEAN AND ENDING                                            *"
echo "************************************************************************"
echo "Upgrading..."
status=$(apt upgrade -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not upgraded         \n"
else
  printf "\r- Upgraded             \n"
fi

echo "Cleaning..."
status=$(apt autoclean 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not cleaned          \n"
else
  printf "\r- Cleaned              \n"
fi

echo "Erasing unecessary files..."
status=$(apt autoremove -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not erased           \n"
else
  printf "\r- Erased             \n"
fi
rm 0
echo "- All done"
