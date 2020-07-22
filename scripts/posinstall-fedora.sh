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
DOWNLOADS="/tmp/pos-install-programs" # Pasta onde os baixar os programas

# Apenas para quando em Dualboot
# GRUB="/etc/default/grub"             # Localização do GRUB do sistema

###############################################################################
# Define as listas                                                            #
PROGRAMS_TO_UNINSTALL=(
)
DNF_PROGRAMS=(
    fedora-workstation-repositories
    gnome-tweak-tool
    google-chrome-stable
    software-properties-common
    nemo nemo-python nemo-fileroller
    alacarte
    breeze-gtk breeze-icon-theme
    mysql-server
    php php-curl php-mysql php-sqlite3 phpunit
    composer
    insync
    mysql-community-server
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
    org.texstudio.TeXstudio
    com.syntevo.SmartGit
)

DNF_MANAGER=(
    google-chrome
)

URLs=(
    https://dev.mysql.com/get/mysql80-community-release-fc32-1.noarch.rpm
    https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-8.0.21-1.fc32.x86_64.rpm
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

# Adiciona DNF-Manager
# Recebe por parâmetro [nome] do DNF-Manager
function addDNFManager {
  echo "PPA $1:"
  status=$(dnf config-manager --set-enabled "$1" -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not added         \n"
  else
      printf "\r- Added             \n"
  fi
}

# Instala programa DNF
# Recebe por parâmetro [nome_de_instalação] do DNF
function installDNF {
  echo "Program $1:"
  status=$(dnf install $1 -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not installed         \n"
  else
      printf "\r- Installed             \n"
  fi
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

# Instala programa .rpm baixado
# Recebe por parâmetro [nome_de_instalação] .rpm
function installRpm {
  echo "Program $1:"
  status=$(rpm -i $1 -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- Not installed         \n"
  else
      printf "\r- Installed             \n"
  fi
}

# Desinstala programa DNF
# Recebe por parâmetro [nome_de_desinstalação] DNF
function uninstallDNF {
  echo "Program $1:"
  if dpkg -l | grep -q $1; then # Só desinstala se estiver instalado
      status=$(dnf remove $1 -y 2> /dev/null) &
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

echo "************************************************************************"
echo "* UNINSTALL SOME PREINSTALLED PROGRAMS                                 *"
echo "************************************************************************"
for program in ${PROGRAMS_TO_UNINSTALL[@]}; do
    uninstallDNF $program
done

echo "************************************************************************"
echo "* DNF_MANAGER REGISTER                                                 *"
echo "************************************************************************"
for ppa in ${DNF_MANAGER[@]}; do
    addDNFManager $ppa
done

echo "Insync baselines..."
sudo rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
sh -c 'echo -e "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/[DISTRIBUTION]/\$releasever/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nenabled=1\nmetadata_expire=120m" >> /etc/yum.repos.d/insync.repo'

echo "MySQL baselines..."
sh -c 'echo -e "[mysql80-community]\nname=MySQL 8.0 Community Server\nbaseurl=http://repo.mysql.com/yum/mysql-8.0-community/el/6/\$basearch/\nenabled=1\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql" >> /etc/yum.repos.d/mysql-community.repo'

###############################################################################
# Atualização das dependências do DNF                                         #
echo "************************************************************************"
echo "* UPDATING DNF DEPENCENCIES                                            *"
echo "************************************************************************"
echo "DNF dependencies"
status=$(dnf update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
    printf "\r- Not updated          \n"
else
    printf "\r- Updated              \n"
fi

echo "************************************************************************"
echo "* INSTALL DNF PROGRAMS                                                 *"
echo "************************************************************************"
for program in ${DNF_PROGRAMS[@]}; do
    installDNF $program
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
echo "* DOWNLOAD PROGRAMS                                                    *"
echo "************************************************************************"
mkdir $DOWNLOADS
for url in ${URLs[@]}; do
    downloadProgram $url
done

echo "************************************************************************"
echo "* INSTALL RPM PROGRAMS                                                 *"
echo "************************************************************************"
rpms=$(find $DOWNLOADS -type f -iregex ".*\.\(rpm\)")
for rpm in $rpms; do
    installRpm $rpm
done

echo "************************************************************************"
echo "* REPLACE NAUTILUS WITH NEMO                                           *"
echo "************************************************************************"
xdg-mime default nemo.desktop inode/directory
uninstallDNF nautilus
uninstallDNF nautilus*
echo "Please, configure Nemo as follows:                                     *"
echo " 1 - Open Alacarte (Main Menu)                                         *"
echo " 2 - Select 'Acessories' > 'New Item'                                  *"
echo " 3 - Set:                                                              *"
echo " 3.1 - name as 'Nemo';                                                 *"
echo " 3.2 - command as '/usr/bin/nemo'                                      *"
echo " 3.3 - image as '/usr/share/icons/gnome/256x256/places/folder.png'     *"
echo "************************************************************************"
echo "* GIT CONFIGURATION                                                    *"
echo "************************************************************************"
echo "Setting global user and e-mail"
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"
echo "- Ready"

echo "************************************************************************"
echo "* UPGRADE, CLEAN AND ENDING                                            *"
echo "************************************************************************"
echo "Cleaning..."
status=$(dnf clean packages 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not cleaned          \n"
else
  printf "\r- Cleaned              \n"
fi
