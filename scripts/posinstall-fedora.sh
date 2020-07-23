#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/ShellScripting

# Para adicionar no futuro:
# - Configuração do usuário global do Git está funcionando?
# - Aparentemente o Fedora apresenta a tela de GRUB mesmo sendo o único
#   Sistema instalado, averiguar configurações de GRUB
# - Instalação do MySQL Server
# - Configuração do MySQL Server
# - Adicionar opções como: --version, -dualboot=true/false
# - Revisar comentários e instruções (Padronizar saídas)

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

DOWNLOADS="/tmp/pos-install-programs" # Pasta onde os baixar os programas

###############################################################################
# Define as listas                                                            #

DNF_PROGRAMS=(
    fedora-workstation-repositories
    gnome-tweak-tool
    google-chrome-stable
    software-properties-common
    nemo nemo-python nemo-fileroller
    alacarte
    breeze-gtk breeze-icon-theme
    php php-curl php-mysql php-sqlite3 phpunit
    composer
    insync
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
    org.kde.kdenlive
    io.atom.Atom
    org.texstudio.TeXstudio
    com.syntevo.SmartGit
)

DNF_MANAGER=(
    google-chrome
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
  echo "DNF $1:"
  status=$(dnf config-manager --set-enabled $1 -y 2> /dev/null) &
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

echo "************************************************************************"
echo "* PREREQUISITS                                                         *"
echo "************************************************************************"

echo "************************************************************************"
echo "* DNF_MANAGER REGISTER                                                 *"
echo "************************************************************************"
for dnf in ${DNF_MANAGER[@]}; do
    addDNFManager $dnf
done

echo "Insync baselines..."
sudo rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key
sh -c 'echo -e "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/\$releasever/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nenabled=1\nmetadata_expire=120m" >> /etc/yum.repos.d/insync.repo'

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
echo ""
echo "************************************************************************"
echo "* GIT CONFIGURATION                                                    *"
echo "************************************************************************"
echo "Setting global user and e-mail"
git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_USER
echo "- Ready"

echo "************************************************************************"
echo "* UPGRADE, CLEAN AND ENDING                                            *"
echo "************************************************************************"
echo "Ugrading..."
status=$(dnf upgrade -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not cleaned          \n"
else
  printf "\r- Cleaned              \n"
fi

echo "Cleaning..."
status=$(dnf clean packages -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status > 0 ]; then
  printf "\r- Not cleaned          \n"
else
  printf "\r- Cleaned              \n"
fi

rm 0
