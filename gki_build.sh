#!/bin/bash

install_packages() {
    echo "Atualizando lista de pacotes e instalando dependências necessárias..."
    sudo apt update
    sudo apt install -y curl git rsync openssl gnutls-bin make
}

update_repo_tool() {
    echo "Instalando ou atualizando a ferramenta repo..."
    mkdir -p ~/bin
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
    export PATH=~/bin:$PATH
}

sync_repository() {
    echo "Sincronizando o repositório do kernel Android 13 (5.10)..."
    mkdir -p android-kernel && cd android-kernel
    repo init -u https://android.googlesource.com/kernel/manifest -b common-android13-5.10
    repo sync
    cd ..
}

run_build_gki_style() {
    echo "Verificando se build.sh existe no diretório build..."
    if [ ! -f "android-kernel/build/build.sh" ]; then
        echo "build.sh não encontrado no diretório android-kernel/build! Certifique-se de que o script está no lugar correto."
        exit 1
    fi

    echo "Iniciando o processo de build com estilo GKI..."
    cd android-kernel/build || { echo "Diretório build não encontrado!"; exit 1; }
    bash build.sh
    cd ../..
}

main() {
    install_packages
    update_repo_tool
    sync_repository
    run_build_gki_style
    echo "Build concluído com sucesso para Android 13 Kernel 5.10!"
}

main
