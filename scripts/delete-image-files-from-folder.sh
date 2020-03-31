#!/usr/bin/env bash

# Marcelo Júnior (MimMarcelo), https://github.com/MimMarcelo/

set -o errexit
set -o pipefail
set -o nounset

# Cria a variável root_folder
# Na sintaxe não pode haver espaços em branco
# O $1 significa: obter o primeiro parâmetro
root_folder=$1

if [ -z $root_folder ]
then
    echo "************************************************************************"
    echo "*                                                                      *"
    echo "* Nenhum diretório informado!                                          *"
    echo "* Por favor informe o diretório no qual as imagens devem ser deletadas *"
    echo "* Ex.: delete-image-files-from-folder.sh /home/user/Documents/folder/  *"
    echo "*                                                                      *"
    echo "************************************************************************"
    exit
fi

if [ ! -d $root_folder ]
then
    echo "************************************************************************"
    echo "*                                                                      *"
    echo "* Caminho informado não é um diretório                                 *"
    echo "* Por favor informe o diretório no qual as imagens devem ser deletadas *"
    echo "* Ex.: delete-image-files-from-folder.sh /home/user/Documents/folder/  *"
    echo "*                                                                      *"
    echo "************************************************************************"
    exit
fi

# Imprime na tela
# O -n significa para não quebrar linha ao final da impressão
echo -n "Pasta selecionada: "
echo $root_folder # Para acessar o valor de uma variável usa $ no início

# A função $() permite pegar o retorno de um comando de terminal e
# possivelmente atribuí-lo a uma variável
files=$(find $root_folder -type f -iregex ".*\.\(jpg\|jpeg\|gif\|bmp\|png\|psd\|tiff\|exif\|raw\|webp\|svg\)")

# Impede que o laço entenda " " (espaços em branco), como separador de registros
IFS=$'\n'

# Laço de repetição for VARIÁVEL in LISTA
# É obrigatório que o "do" venha apenas na linha seguinte
for file in $files
do
    rm $file

    # Teste condicional if [ CONDIÇÃO ] # É obrigatório o uso dos espaços
    # É obrigatório que o "then" venha apenas na linha seguinte
    if [ $? -eq 0 ]
    then
        echo "Arquivo: "$file" removido com sucesso!"
    else
        echo "Falha ao tentar remover o arquivo: "$file
    fi
done
