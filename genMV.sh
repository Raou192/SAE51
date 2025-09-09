#!/bin/bash

set -x

VM_NAME="Debian1"
RAM=4096
OS_TYPE="Debian_64"

VM_PATH="$HOME/VirtualBox VMs/$VM_NAME"

VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --register

VBoxManage modifyvm "$VM_NAME" \
  --memory "$RAM"

#VBoxManage unregistervm "$VM_NAME" --delete

# rajouter input, gestion d'erreurs, rajoouter les arguments
