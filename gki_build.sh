#!/bin/bash

# Credits: @LSEYTHING ON TELEGRAM

install_packages() {
    echo "Updating package list and installing necessary packages..."
    sudo apt update
    sudo apt install -y curl git rsync openssl gnutls-bin make
}

update_repo() {
    echo "Installing or updating repo tool..."
    mkdir -p ~/bin
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
    export PATH=~/bin:$PATH
}

sync_repository() {
    echo "Syncing repository..."
    repo init -u https://android.googlesource.com/kernel/manifest -b common-android13-5.15
    repo sync
}

download_build_sh() {
    echo "Checking if build.sh exists..."
    if [ ! -f "builder.sh" ]; then
        echo "builder.sh not found! Download or place the script in the current directory."
        exit 1
    else
        echo "builder.sh found."
    fi
}

start_build() {
    echo "Navigating to experimental directory..."
    cd experimental || { echo "experimental directory not found!"; exit 1; }
    
    echo "Running builder.sh..."
    bash builder.sh
}

main() {
    install_packages
    update_repo
    sync_repository
    download_build_sh
    start_build
    echo "Your preparation and build finished."
}

main
