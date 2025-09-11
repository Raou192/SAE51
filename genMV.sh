#!/bin/bash

#set -x

OS_TYPE="Debian_64"
SATA_CTL_NAME="SATA"
MAX_RAM_MB=16384
MAX_DISK_GB=64
ISO_DIR="$HOME/ISOs"
ISO_FILE="$ISO_DIR/debian-13.1.0-amd64-netinst.iso"

check_vm() {
    local vm="$1"
    if ! VBoxManage list vms | awk -F\" '{print $2}' | grep -Fxq -- "$vm"; then
        echo "Erreur : la VM '$vm' n'existe pas."
        exit 1
    fi
}

if [ $# -lt 1 ]; then
    echo "Usage: $0 [L|N|S|D|A] [Nom_VM] [RAM_MiB] [Disque_Go]"
    exit 1
fi

ACTION=$1
VM_NAME=$2
VM_PATH="$HOME/VirtualBox VMs/$VM_NAME"

#L pour lister les MV
if [ "$ACTION" = "L" ]; then
    VBoxManage list vms >/dev/null 2>&1
    echo ""
    echo "===================== Métadonnées ====================="
    printf "%-30s %-20s %-20s\n" "Nom VM" "Créé à" "Auteur"
    while read -r name; do
        created=$(VBoxManage getextradata "$name" "meta/created_at" 2>/dev/null | sed -n 's/^Value: //p')
        owner=$(VBoxManage getextradata "$name" "meta/owner" 2>/dev/null | sed -n 's/^Value: //p')
        [ -z "$created" ] && created="-"
        [ -z "$owner" ] && owner="-"
        printf "%-30s %-20s %-20s\n" "$name" "$created" "$owner"
    done < <(VBoxManage list vms | awk -F\" '{print $2}')
    exit 0
fi

#N pour les créer
if [ "$ACTION" = "N" ]; then
    if [ -z "$VM_NAME" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ]; then
        echo "Usage: N <Nom_VM> <RAM_MiB> <DISK_Go>"
        exit 1
    fi

    RAM="$3"
    DISK_SIZE_GB="$4"

    if [ "$RAM" -gt "$MAX_RAM_MB" ]; then
        echo "Erreur: RAM max $MAX_RAM_MB Mo"
        exit 1
    fi

    if [ "$DISK_SIZE_GB" -gt "$MAX_DISK_GB" ]; then
        echo "Erreur: Disque max $MAX_DISK_GB Go"
        exit 1
    fi

    if VBoxManage list vms | awk -F\" '{print $2}' | grep -Fxq "$VM_NAME"; then
        echo "Erreur: VM '$VM_NAME' existe déjà"
        exit 1
    fi

    echo "Création VM $VM_NAME | RAM=${RAM}Mo | Disque=${DISK_SIZE_GB}Go"
    VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --basefolder "$HOME/VirtualBox VMs" >/dev/null 2>&1
    VBoxManage registervm "$VM_PATH/$VM_NAME.vbox" >/dev/null 2>&1
    VBoxManage modifyvm "$VM_NAME" --memory "$RAM" --nic1 nat \
        --boot1 dvd --boot2 disk --boot3 none --boot4 none >/dev/null 2>&1

    #Le Disque
    VDI_PATH="$VM_PATH/$VM_NAME.vdi"
    VBoxManage createmedium disk --filename "$VDI_PATH" --size $((DISK_SIZE_GB*1024)) >/dev/null 2>&1
    VBoxManage storagectl "$VM_NAME" --name "$SATA_CTL_NAME" --add sata --controller IntelAhci >/dev/null 2>&1
    VBoxManage storageattach "$VM_NAME" --storagectl "$SATA_CTL_NAME" --port 0 --device 0 --type hdd --medium "$VDI_PATH" >/dev/null 2>&1

    #ISO Debian
    mkdir -p "$ISO_DIR"
    if [ ! -f "$ISO_FILE" ]; then
        echo "Téléchargement Debian netinst ISO..."
        wget -O "$ISO_FILE" "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.1.0-amd64-netinst.iso" >/dev/null 2>&1
    fi

    #On attache l'ISO
    VBoxManage storagectl "$VM_NAME" --name "IDE" --add ide >/dev/null 2>&1
    VBoxManage storageattach "$VM_NAME" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ISO_FILE" >/dev/null 2>&1

    #Les Métadonnées
    VBoxManage setextradata "$VM_NAME" "meta/created_at" "$(date +"%d-%m-%Y %Hh%M")" >/dev/null 2>&1
    VBoxManage setextradata "$VM_NAME" "meta/owner" "$USER" >/dev/null 2>&1

    echo "VM $VM_NAME prête avec ISO Debian netinst"
    exit 0
fi

#S pour la suspression
if [ "$ACTION" = "S" ]; then
    if [ -z "$VM_NAME" ]; then
        echo "Nom VM manquant"
        exit 1
    fi

    check_vm "$VM_NAME"

    VBoxManage controlvm "$VM_NAME" poweroff >/dev/null 2>&1 || true
    if VBoxManage unregistervm "$VM_NAME" --delete >/dev/null 2>&1; then
        echo "VM $VM_NAME supprimée"
        exit 0
    fi

    echo "Impossible de supprimer la VM $VM_NAME : elle est en cours d’utilisation"
    exit 1
fi

#D pour les démarer
if [ "$ACTION" = "D" ]; then
    if [ -z "$VM_NAME" ]; then
        echo "Nom VM manquant"
        exit 1
    fi

    check_vm "$VM_NAME"

    if VBoxManage startvm "$VM_NAME" --type gui >/dev/null 2>&1; then
        echo "VM $VM_NAME démarrée"
        exit 0
    fi

    echo "VM $VM_NAME est déjà en cours d’utilisation"
    exit 1
fi

#A pour les arreter
if [ "$ACTION" = "A" ]; then
    if [ -z "$VM_NAME" ]; then
        echo "Nom VM manquant"
        exit 1
    fi

    check_vm "$VM_NAME"
    VBoxManage controlvm "$VM_NAME" poweroff >/dev/null 2>&1
    echo "VM $VM_NAME arrêtée"
    exit 0
fi

if [ "$ACTION" != "L" ] && [ "$ACTION" != "N" ] && [ "$ACTION" != "S" ] && [ "$ACTION" != "D" ] && [ "$ACTION" != "A" ]; then
    echo "Action inconnue : $ACTION"
    exit 1
fi
