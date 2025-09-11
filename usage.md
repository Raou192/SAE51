# Usage et explications du script genMV.sh

**Auteurs :** [Temagoult Samy & Pinel Raoul]
**Date :** 11 septembre 2025  

## Résumé
Ce document explique le fonctionnement du script `genMV.sh` qui permet de créer, gérer et supprimer des machines virtuelles VirtualBox. Chaque ligne du script est détaillée pour comprendre son rôle, ses paramètres et les choix faits.

---

## Déclarations initiales

```bash
#!/bin/bash
```
- Indique que le script doit être exécuté avec `bash`.

```bash
OS_TYPE="Debian_64"
SATA_CTL_NAME="SATA"
MAX_RAM_MB=16384
MAX_DISK_GB=64
ISO_DIR="$HOME/ISOs"
ISO_FILE="$ISO_DIR/debian-13.1.0-amd64-netinst.iso"
```
- `OS_TYPE` : type d’OS pour la VM (ici Debian 64 bits).  
- `SATA_CTL_NAME` : nom du contrôleur SATA pour le disque.  
- `MAX_RAM_MB` et `MAX_DISK_GB` : limites maximales pour RAM et disque.  
- `ISO_DIR` : dossier où sera stockée l’ISO Debian.  
- `ISO_FILE` : chemin complet de l’ISO netinst à attacher à la VM.

---

## Fonction de vérification d’existence d’une VM

```bash
check_vm() {
    local vm="$1"
    if ! VBoxManage list vms | awk -F\" '{print $2}' | grep -Fxq -- "$vm"; then
        echo "Erreur : la VM '$vm' n'existe pas."
        exit 1
    fi
}
```
- `check_vm` : fonction pour vérifier qu’une VM existe avant de la manipuler.  
- `VBoxManage list vms` : liste toutes les VM.  
- `awk -F" '{print $2}'` : récupère le nom exact de chaque VM (entre guillemets).  
- `grep -Fxq -- "$vm"` : vérifie si le nom passé en paramètre correspond exactement à une VM existante.  
- Si la VM n’existe pas, le script affiche une erreur et s’arrête.

---

## Vérification des arguments

```bash
if [ $# -lt 1 ]; then
    echo "Usage: $0 [L|N|S|D|A] [Nom_VM] [RAM_MiB] [Disque_Go]"
    exit 1
fi
```
- `$#` : nombre d’arguments passés au script.  
- Si aucun argument n’est fourni, le script affiche l’usage et s’arrête.

```bash
ACTION=$1
VM_NAME=$2
VM_PATH="$HOME/VirtualBox VMs/$VM_NAME"
```
- `ACTION` : première lettre de commande (`L`, `N`, `S`, `D`, `A`).  
- `VM_NAME` : nom de la VM (si applicable).  
- `VM_PATH` : chemin du dossier de la VM dans le home.

---

## Liste des VM et métadonnées (`L`)

```bash
if [ "$ACTION" = "L" ]; then
    VBoxManage list vms >/dev/null 2>&1
    echo ""
    echo "===================== Métadonnées ====================="
    printf "%-30s %-20s %-20s
" "Nom VM" "Créé à" "Auteur"
```
- Vérifie si l’action est `L` pour lister les VM.  
- `VBoxManage list vms >/dev/null` : teste la commande.  
- `printf` : affiche un en-tête formaté pour le tableau des métadonnées.

```bash
    while read -r name; do
        created=$(VBoxManage getextradata "$name" "meta/created_at" 2>/dev/null | sed -n 's/^Value: //p')
        owner=$(VBoxManage getextradata "$name" "meta/owner" 2>/dev/null | sed -n 's/^Value: //p')
        [ -z "$created" ] && created="-"
        [ -z "$owner" ] && owner="-"
        printf "%-30s %-20s %-20s
" "$name" "$created" "$owner"
    done < <(VBoxManage list vms | awk -F" '{print $2}')
```
- Boucle sur toutes les VM pour récupérer les métadonnées.  
- `getextradata` : récupère les données `meta/created_at` et `meta/owner`.  
- `sed` : enlève le préfixe `Value: `.  
- Si pas de métadonnées, affiche `-`.  
- Affiche la ligne formatée pour chaque VM.

---

## Création d’une VM (`N`)

```bash
if [ "$ACTION" = "N" ]; then
    if [ -z "$VM_NAME" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ]; then
        echo "Usage: N <Nom_VM> <RAM_MiB> <DISK_Go>"
        exit 1
    fi
```
- Vérifie que le nom, la RAM et le disque sont fournis.

```bash
    RAM="$3"
    DISK_SIZE_GB="$4"
    [ "$RAM" -gt "$MAX_RAM_MB" ] && { echo "Erreur: RAM max $MAX_RAM_MB Mo"; exit 1; }
    [ "$DISK_SIZE_GB" -gt "$MAX_DISK_GB" ] && { echo "Erreur: Disque max $MAX_DISK_GB Go"; exit 1; }
```
- Assigne les valeurs aux variables et vérifie qu’elles ne dépassent pas les limites.

```bash
    if VBoxManage list vms | awk -F" '{print $2}' | grep -Fxq "$VM_NAME"; then
        echo "Erreur: VM '$VM_NAME' existe déjà"
        exit 1
    fi
```
- Vérifie qu’une VM du même nom n’existe pas déjà.

```bash
    VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --basefolder "$HOME/VirtualBox VMs" >/dev/null 2>&1
    VBoxManage registervm "$VM_PATH/$VM_NAME.vbox" >/dev/null 2>&1
    VBoxManage modifyvm "$VM_NAME" --memory "$RAM" --nic1 nat         --boot1 dvd --boot2 disk --boot3 none --boot4 none >/dev/null 2>&1
```
- Crée la VM, l’enregistre et configure la mémoire, le réseau NAT et l’ordre de boot.

```bash
    VDI_PATH="$VM_PATH/$VM_NAME.vdi"
    VBoxManage createmedium disk --filename "$VDI_PATH" --size $((DISK_SIZE_GB*1024)) >/dev/null 2>&1
    VBoxManage storagectl "$VM_NAME" --name "$SATA_CTL_NAME" --add sata --controller IntelAhci >/dev/null 2>&1
    VBoxManage storageattach "$VM_NAME" --storagectl "$SATA_CTL_NAME" --port 0 --device 0 --type hdd --medium "$VDI_PATH" >/dev/null 2>&1
```
- Crée un disque VDI de la taille demandée et l’attache au contrôleur SATA.

```bash
    mkdir -p "$ISO_DIR"
    if [ ! -f "$ISO_FILE" ]; then
        echo "Téléchargement Debian netinst ISO..."
        wget -O "$ISO_FILE" "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.1.0-amd64-netinst.iso" >/dev/null 2>&1
    fi
```
- Crée le dossier ISO et télécharge Debian si nécessaire.

```bash
    VBoxManage storagectl "$VM_NAME" --name "IDE" --add ide >/dev/null 2>&1
    VBoxManage storageattach "$VM_NAME" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$ISO_FILE" >/dev/null 2>&1
```
- Ajoute un contrôleur IDE pour le lecteur DVD et y attache l’ISO Debian.

```bash
    VBoxManage setextradata "$VM_NAME" "meta/created_at" "$(date +"%d-%m-%Y %Hh%M")" >/dev/null 2>&1
    VBoxManage setextradata "$VM_NAME" "meta/owner" "$USER" >/dev/null 2>&1
    exit 0
fi
```
- Ajoute les métadonnées de date de création et utilisateur.  
---

## Suppression d’une VM (`S`)

```bash
if [ "$ACTION" = "S" ]; then
    [ -z "$VM_NAME" ] && { echo "Nom VM manquant"; exit 1; }
    check_vm "$VM_NAME"
    VBoxManage controlvm "$VM_NAME" poweroff >/dev/null 2>&1 || true
    VBoxManage unregistervm "$VM_NAME" --delete >/dev/null 2>&1
    exit 0
fi
```
- Vérifie le nom, teste que la VM existe, l’éteint si nécessaire puis la supprime complètement.  

---

## Démarrage d’une VM (`D`)

```bash
if [ "$ACTION" = "D" ]; then
    [ -z "$VM_NAME" ] && { echo "Nom VM manquant"; exit 1; }
    check_vm "$VM_NAME"
    VBoxManage startvm "$VM_NAME" --type gui >/dev/null 2>&1
    exit 0
fi
```
- Vérifie que la VM existe puis la démarre en mode GUI.  

---

## Arrêt d’une VM (`A`)

```bash
if [ "$ACTION" = "A" ]; then
    [ -z "$VM_NAME" ] && { echo "Nom VM manquant"; exit 1; }
    check_vm "$VM_NAME"
    VBoxManage controlvm "$VM_NAME" poweroff >/dev/null 2>&1
    exit 0
fi
```
- Vérifie que la VM existe puis l’arrête.

---

## Gestion d’erreur pour action inconnue

```bash
if [ "$ACTION" != "L" ] && [ "$ACTION" != "N" ] &&    [ "$ACTION" != "S" ] && [ "$ACTION" != "D" ] &&    [ "$ACTION" != "A" ]; then
    echo "Action inconnue : $ACTION"
    exit 1
fi
```
- Remplace l’ancien bloc `else ... fi`.  
- Si l’action n’est pas reconnue, le script affiche un message et s’arrête.

---

## Conclusion
Ce script est conçu pour automatiser entièrement la création et la gestion de VM Debian sous VirtualBox, en intégrant la vérification des erreurs, l’ajout de métadonnées, et le téléchargement automatique de l’ISO Debian. Chaque étape est sécurisée et vérifie les conditions avant exécution pour éviter les conflits ou les erreurs.