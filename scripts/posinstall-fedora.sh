#!/usr/bin/env bash

###############################################################################
# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/ShellScripting

# Para adicionar no futuro:
# - Configuração do usuário global do Git está funcionando?
# - Instalação do snap (e vscode, OBStudio, scrcpy)
# - Instalação do MySQL Server
# - Configuração do MySQL Server
# - Adicionar opções como: --version, -dualboot=true/false
# - Verificação de status das instalações não está funcionando
# - Revisar comentários
# - Criar função que executa comandos como usuário local $USER 

###############################################################################
# Define as variáveis

spin='-\|/' # Utilizado na função [loading], representa o carregamento

GIT_EMAIL="rokermarcelo@gmail.com"   # e-mail global do Git
GIT_USER="Marcelo Júnior"            # Usuário global do Git
USER='marcelo'
# status=0

###############################################################################
# Define as listas

DNF_PROGRAMS=(
    gnome-tweak-tool extension
    software-properties-common
    breeze-cursor-theme
    php php-curl php-mysql php-sqlite3 php-pgsql phpunit
    composer
    google-chrome 
    https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
    ffmpeg
    google-chrome-stable
    snapd
    \*-firmware
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
echo "************************************************************************"
echo "************************************************************************"
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

# Configuração para melhorar a velocidade de resposta do DNF
echo 'fastestmirror=True' >> /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf
dnf clean all

#Configuração do RPM-fusion
installDNF https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
installDNF https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf groupupdate core -y

#Configuração de recursos multimídia
dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf groupupdate sound-and-video -y

# Habilita o gerenciador DNF fedora-extras
echo "Manager fedora-extras"
status=$(dnf config-manager --set-enabled fedora-extras -y 2> /dev/null) &
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

echo "Google Chrome"
installDNF fedora-workstation-repositories
dnf config-manager --set-enabled google-chrome -y

echo "Update DNF dependencies"
dnf update -y

echo "Update Flatpak dependencies"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update -y

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
echo "* INSTALL SNAP PROGRAMS"
systemctl start snapd.seeded.service
systemctl start snapd.service

systemctl enable snapd.seeded.service
systemctl enable snapd.service

mkdir /snap
ln -s /var/lib/snapd/snap /snap

snap refresh
snap install core
snap install code
snap install scrcpy
snap install obs-studio

snap connect obs-studio:alsa
snap connect obs-studio:audio-record
snap connect obs-studio:avahi-control
snap connect obs-studio:camera
snap connect obs-studio:jack1
snap connect obs-studio:kernel-module-observe

echo "************************************************************************"
echo "* GIT GLOBAL CONFIGURATION"
sudo -H -u $USER bash -c "git config --global user.email \"$GIT_EMAIL\""
sudo -H -u $USER bash -c "git config --global user.name \"$GIT_USER\""

echo "************************************************************************"
echo "* CLEAN AND ENDING"
echo "Clean"
status=$(dnf clean all 2> /dev/null) &
loading $! # Envia o [id do processo] para a função de loading

if [ $status -gt 0 ]; then
    printf "\r- [FAILURE]                                                    \n"
else
    printf "\r- [OK]                                                         \n"
fi

echo "************************************************************************"
echo "* CREATE HOME FOLDERS"
sudo -H -u $USER bash -c 'mkdir ~/Projects'
sudo -H -u $USER bash -c 'mkdir ~/Games'
sudo -H -u $USER bash -c 'mkdir ~/Insync'
sudo -H -u $USER bash -c 'mkdir ~/Insync/Documents'
sudo -H -u $USER bash -c 'mkdir ~/Insync/Music'
sudo -H -u $USER bash -c 'mkdir ~/Insync/Pictures'
sudo -H -u $USER bash -c 'mkdir ~/Insync/Projects'
sudo -H -u $USER bash -c 'mkdir ~/Insync/Videos'
sudo -H -u $USER bash -c 'mkdir ~/Insync/Games'
echo "************************************************************************"
echo "* CREATE SYMBOLIC LINKS"
sudo -H -u $USER bash -c 'ln -s ~/Insync/Documents/ ~/Documents/_Documents'
sudo -H -u $USER bash -c 'ln -s ~/Insync/Music/ ~/Music/_Music'
sudo -H -u $USER bash -c 'ln -s ~/Insync/Pictures/ ~/Pictures/_Pictures'
sudo -H -u $USER bash -c 'ln -s ~/Insync/Projects/ ~/Projects/_Projects'
sudo -H -u $USER bash -c 'ln -s ~/Insync/Videos/ ~/Videos/_Videos'
sudo -H -u $USER bash -c 'ln -s ~/Insync/Games/ ~/Games/_Games'

echo "************************************************************************"
echo "* FORMATE TERMINAL"
sudo -H -u $USER bash -c 'echo "PS1=\"\[\e[1;32m\]\u@\h \[\e[37m\]\w $ \[\e[0;37m\]\"" >> ~/.bashrc'
echo "Você também pode definir um nome para sua máquina com o comando:"
echo "hostnamectl set-hostname nome-da-maquina"
rm 0
