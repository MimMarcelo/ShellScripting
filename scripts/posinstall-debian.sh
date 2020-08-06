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
DOWNLOADS="/tmp/install-programs" # Pasta onde os baixar os programas

# Apenas para quando em Dualboot
# GRUB="/etc/default/grub"             # Localização do GRUB do sistema

###############################################################################
# Define as listas                                                            #
PROGRAMS_TO_UNINSTALL=(
  apache2
)
APT_PROGRAMS=(
    software-properties-common
    breeze frei0r-plugins
    mysql-server
    php php-curl php-mbstring php-mysql php-sqlite3 phpunit
    git
    flatpak gnome-software-plugin-flatpak
    inkscape
    insync
    google-chrome-stable
    -f
)

FLATPAK_PROGRAMS=(
    com.google.AndroidStudio
    com.obsproject.Studio
    org.apache.netbeans
    org.audacityteam.Audacity
    org.gimp.GIMP
    com.getpostman.Postman
    com.spotify.Client
    org.stellarium.Stellarium
    com.sweethome3d.Sweethome3d
    org.videolan.VLC
    org.kde.kdenlive
    io.atom.Atom
    org.texstudio.TeXstudio
    com.syntevo.SmartGit
)

PPAs=(
    ppa:ondrej/php
    ppa:graphics-drivers/ppa
)

URLs=(
    https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.21-1ubuntu18.04_amd64.deb
    https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
    http://ftp.br.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.7_all.deb
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
echo "Chrome baselines..."
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

echo "Insync baselines..."
sh -c 'echo "deb http://apt.insync.io/debian buster non-free contrib" >> /etc/apt/sources.list.d/insync.list'
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ACCAF35C

# Este passo de download deve ser antes do apt update, pois BAIXA o arquivo
# de configuração do repositório do MySQL
echo "************************************************************************"
echo "* DOWNLOAD PROGRAMS                                                    *"
echo "************************************************************************"
mkdir $DOWNLOADS
for url in ${URLs[@]}; do
    downloadProgram $url
done

# Este passo de download deve ser antes do apt update, pois INSTALA o arquivo
# de configuração do repositório do MySQL
echo "************************************************************************"
echo "* INSTALL DEB PROGRAMS                                                 *"
echo "************************************************************************"
debs=$(find $DOWNLOADS -type f -iregex ".*\.\(deb\)")
for deb in $debs; do
    installDeb $deb
done

###############################################################################
# Atualização das dependências do APT                                     #
echo "************************************************************************"
echo "* UPDATING APT DEPENCENCIES                                            *"
echo "************************************************************************"
echo "APT dependencies"
status=$(apt update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
    printf "\r- Not updated          \n"
else
    printf "\r- Updated              \n"
fi

echo "************************************************************************"
echo "* INSTALL APT PROGRAMS                                                 *"
echo "************************************************************************"
for program in ${APT_PROGRAMS[@]}; do
    installApt $program
done

###############################################################################
# Atualização das dependências do flatpak                                     #
echo "************************************************************************"
echo "* UPDATING FLATPAK DEPENCENCIES                                        *"
echo "************************************************************************"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "Flatpak dependencies"
status=$(flatpak update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
    printf "\r- Not updated          \n"
else
    printf "\r- Updated              \n"
fi

echo "************************************************************************"
echo "* INSTALL FLATPAK PROGRAMS                                             *"
echo "************************************************************************"
for program in ${FLATPAK_PROGRAMS[@]}; do
    installFlatpak $program
done

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
git config --global user.email "rokermarcelo@gmail.com"
git config --global user.name "Marcelo Júnior"
echo "- Ready"

echo "************************************************************************"
echo "* UPGRADE, CLEAN AND ENDING                                            *"
echo "************************************************************************"
dpkg --configure -a
apt --fix-broken install -y
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
