#!/bin/bash

set -x

VM_NAME="Debian46"
RAM=4096
OS_TYPE="Debian_64"

VM_PATH="$HOME/VirtualBox VMs/$VM_NAME"

VBoxManage createvm --name "$VM_NAME"

samy="$?"

if [ "$samy" != 0 ]; then
	echo " mais non jeune homme"
else
	echo " bravo jeune homme"
fi

VBoxManage registervm "$VM_PATH/$VM_NAME.vbox"

VBoxManage modifyvm "$VM_NAME" --memory "$RAM"

VBoxManage unregistervm "$VM_NAME" --delete

# rajouter input, gestion d'erreurs, rajoouter les arguments
