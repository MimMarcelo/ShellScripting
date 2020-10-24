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

SYSTEM_NAME=$(lsb_release -sc);

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
  libreoffice
)

APT_PROGRAMS=(
    build-essential dkms linux-headers-$(uname -r)
    software-properties-common
    breeze frei0r-plugins
    adoptopenjdk-8-hotspot
    mariadb-server
    php php-curl php-mbstring php-mysql php-sqlite3 phpunit
    git
    flatpak gnome-software-plugin-flatpak
    insync
    google-chrome-stable
    virtualbox-6.1
    vlc
    composer
    aptitude
)

FLATPAK_PROGRAMS=(
    com.google.AndroidStudio
    io.atom.Atom
    org.audacityteam.Audacity
    org.gimp.GIMP
    org.inkscape.Inkscape
    org.kde.kdenlive
    org.libreoffice.LibreOffice
    com.obsproject.Studio
    org.apache.netbeans
    com.getpostman.Postman
    com.spotify.Client
    org.stellarium.Stellarium
    com.sweethome3d.Sweethome3d
)

URLs=(
    https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community_8.0.21-1ubuntu18.04_amd64.deb
    http://ftp.br.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.7_all.deb
    http://iriun.gitlab.io/iriunwebcam.deb
    https://cdn.change-vision.com/files/astah-uml_8.2.0.b743f7-0_all.deb
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
# function addPPA {
#   echo "PPA $1:"
#   status=$(apt-add-repository "$1" -y 2> /dev/null) &
#   loading $! # Envia o [id do processo] para a função de loading
#
#   if [ $status > 0 ]; then
#       printf "\r- Not added         \n"
#   else
#       printf "\r- Added             \n"
#   fi
# }

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
# for ppa in ${PPAs[@]}; do
#     addPPA $ppa
# done
echo "Chrome baselines..."
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

echo "Insync baselines..."
sh -c 'echo "deb http://apt.insync.io/debian buster non-free contrib" >> /etc/apt/sources.list.d/insync.list'
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys ACCAF35C

echo "VirtualBox baselines..."
sh -c 'echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian buster contrib" >> /etc/apt/sources.list.d/virtualbox.list'
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add -

echo "Java 1.8 para o Astah..."
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -
sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/

echo "PHP mais recente..."
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/sury-php.list'

# Este passo de download deve ser antes do apt update, pois BAIXA o arquivo
# de configuração do repositório do MySQL
echo "************************************************************************"
echo "* DOWNLOAD PROGRAMS                                                    *"
echo "************************************************************************"
mkdir $DOWNLOADS
for url in ${URLs[@]}; do
    downloadProgram $url
done

apt --fix-broken install -y

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
echo "* GIT CONFIGURATION                                                    *"
echo "************************************************************************"
echo "Setting global user and e-mail"
sudo -H -u marcelo git config --global user.email "$GIT_EMAIL"
sudo -H -u marcelo git config --global user.name "$GIT_USER"
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
    expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
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
sed -e "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/" -e "s/#GRUB_DISABLE_RECOVERY=.*/GRUB_DISABLE_RECOVERY=\"true\"\nGRUB_DISABLE_SUBMENU=\"y\"/" "$GRUB" >"$DOWNLOADS/grub"
cp "$GRUB" "$GRUB.original"
mv "$DOWNLOADS/grub" "$GRUB"
update-grub

echo "************************************************************************"
echo "* UPGRADE, CLEAN AND ENDING                                            *"
echo "************************************************************************"
dpkg --configure -a

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
rm $DOWNLOADS
echo "- All done"
