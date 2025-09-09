#!/bin/bash

set -x

RAM=4096
OS_TYPE="Debian_64"

if [ $# -lt 1 ]; then
	echo "Usage: $0 [L|N|S|D|A] [Nom_VM]"
	exit 1
fi

ACTION=$1
VM_NAME=$2
VM_PATH="$HOME/VirtualBox VMs/$VM_NAME"

if [ "$ACTION" = "L" ]; then
	VBoxManage list vms

elif [ "$ACTION" = "N" ]; then
	if [ -z "$VM_NAME" ]; then
		echo "Nom de VM manquant"
	exit 1
	fi
	VBoxManage createvm --name "$VM_NAME"

	samy="$?"
	if [ "$samy" != 0 ]; then
	echo "Erreur création VM"
	exit 1
	else
	echo "VM $VM_NAME créée"
	fi
	VBoxManage registervm "$VM_PATH/$VM_NAME.vbox"

	VBoxManage modifyvm "$VM_NAME" --memory "$RAM"

elif [ "$ACTION" = "S" ]; then
	if [ -z "$VM_NAME" ]; then
	echo "Nom de VM manquant"
	exit 1
	fi
	VBoxManage unregistervm "$VM_NAME" --delete
	echo "VM $VM_NAME supprimée"

elif [ "$ACTION" = "D" ]; then
	if [ -z "$VM_NAME" ]; then
	echo "Nom de VM manquant"
	exit 1
	fi
	VBoxManage startvm "$VM_NAME"
	echo "VM $VM_NAME démarrée"

elif [ "$ACTION" = "A" ]; then
	if [ -z "$VM_NAME" ]; then
	echo "Nom de VM manquant"
	exit 1
	fi
	VBoxManage controlvm "$VM_NAME" poweroff
	echo "VM $VM_NAME arrêtée"

else
	echo "Action inconnue : $ACTION"
	echo "Usage: $0 [L|N|S|D|A] [Nom_VM]"
	exit 1
fi

#rajouter input ram en 3 eme arguments
