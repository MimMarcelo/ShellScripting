#!/usr/bin/env bash

###############################################################################
# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/ShellScripting

# Para adicionar no futuro:
# - Configuração do usuário global do Git está funcionando?
# - Instalação do snap (e vscode, OBStudio)
# - Instalação do MySQL Server
# - Configuração do MySQL Server
# - Adicionar opções como: --version, -dualboot=true/false
# - Verificação de status das instalações não está funcionando
# - Revisar comentários

###############################################################################
# Define as variáveis

spin='-\|/' # Utilizado na função [loading], representa o carregamento

# status=0

###############################################################################
# Define as listas

DNF_PROGRAMS=(
    fedora-workstation-repositories
    gnome-tweak-tool
    software-properties-common
    breeze-gtk breeze-icon-theme breeze-cursor-theme
    php php-curl php-mysql php-sqlite3 phpunit
    composer
    https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
)

FLATPAK_PROGRAMS=(
    com.google.AndroidStudio
    org.audacityteam.Audacity
    org.gimp.GIMP
    org.inkscape.Inkscape
    org.stellarium.Stellarium
    com.sweethome3d.Sweethome3d
    org.kde.kdenlive
)

###############################################################################
# Define as funções

# Exibe elemento alusivo ao carregamento do processo
# Recebe por parâmetro [$!] do processo
function loading {
  i=0
  while kill -0 $1 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r- loading [${spin:$i:1}]"
    sleep .1
  done
}

# Instala programa DNF
# Recebe por parâmetro [nome_de_instalação] do DNF
function installDNF {
  echo "Program $1:"
  status=$(dnf install $1 -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- [FAILURE]                                                  \n"
  else
      printf "\r-[OK]                                                        \n"
  fi
}

# Instala programa Flatpak
# Recebe por parâmetro [nome_de_instalação] Flatpak
function installFlatpak {
  echo "Program $1:"
  status=$(flatpak install flathub $1 -y 2> /dev/null) &
  loading $! # Envia o [id do processo] para a função de loading

  if [ $status > 0 ]; then
      printf "\r- [FAILURE]                                                  \n"
  else
      printf "\r-[OK]                                                        \n"
  fi
}

###############################################################################
# Pré-requisitos para execução
echo ""
echo "************************************************************************"
echo "* PREREQUISITS"

# Verifica se o script está sendo executado como sudo
echo "root user"
if [ $EUID -ne 0 ]; then
   printf "\r- [FAILURE]: This script must be run as root                    \n"
   exit 1
else
   printf "\r- [OK]                                                          \n"
fi

# Habilita o gerenciador DNF fedora-extras
echo "Manager fedora-extras"
status=$(dnf config-manager --set-enabled fedora-extras -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "Manager google-chrome"
status=$(dnf config-manager --set-enabled google-chrome -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "Key Insync"
status=$(rpm --import https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "Repository Insync"
sh -c 'echo -e "[insync]\nname=insync repo\nbaseurl=http://yum.insync.io/fedora/\$releasever/\ngpgcheck=1\ngpgkey=https://d2t3ff60b2tol4.cloudfront.net/repomd.xml.key\nenabled=1\nmetadata_expire=120m" >> /etc/yum.repos.d/insync.repo'
printf "\r- [OK]                                                             \n"

echo "Update DNF dependencies"
status=$(dnf update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "Update Flatpak dependencies"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
status=$(flatpak update -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo ""
echo "************************************************************************"
echo "* INSTALL DNF PROGRAMS"
for program in ${DNF_PROGRAMS[@]}; do
    installDNF $program
done

echo ""
echo "************************************************************************"
echo "* INSTALL FLATPAK PROGRAMS"
for program in ${FLATPAK_PROGRAMS[@]}; do
    installFlatpak $program
done

echo ""
echo "************************************************************************"
echo "* REPLACE NAUTILUS WITH NEMO"
xdg-mime default nemo.desktop inode/directory

echo "Remove Nautilus"
status=$(dnf remove nautilus -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "Remove Nautilus*"
status=$(dnf remove nautilus* -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo ""
echo "************************************************************************"
echo "Please, configure Nemo as follows:"
echo " 1 - Open Alacarte (Main Menu)"
echo " 2 - Select 'Acessories' > 'New Item'"
echo " 3 - Set:"
echo " 3.1 - name as 'Nemo'"
echo " 3.2 - command as '/usr/bin/nemo'"
echo " 3.3 - image as '/usr/share/icons/gnome/256x256/places/folder.png'"
echo ""
echo "************************************************************************"
echo "Please, configure Git as follows:"
echo " 1 - git config --global user.email 'GIT_EMAIL'"
echo " 2 - git config --global user.name 'GIT_USER'"

echo "************************************************************************"
echo "* UPGRADE, CLEAN AND ENDING"
echo "Ugrade"
status=$(dnf upgrade -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "Clean"
status=$(dnf clean packages -y 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "************************************************************************"
echo "* CREATE SYMBOLIC LINKS"
ln -s ~/Insync/Documents/ Documents/_Documents
ln -s ~/Insync/Music/ Music/_Music
ln -s ~/Insync/Pictures/ Pictures/_Pictures
ln -s ~/Insync/Projects/ Projects/_Projects
ln -s ~/Insync/Videos/ Videos/_Videos
ln -s ~/Insync/Games/ Games/_Games

echo "************************************************************************"
echo "* FORMATE TERMINAL"
echo PS1=\"\[\e[1;32m\]\u@\h \[\e[37m\]\w $ \[\e[0;37m\]\" >> ~/.bashrc
rm 0
