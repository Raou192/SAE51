# SAE51
 Script d’automatisation VirtualBox (genMV.sh)

**Auteurs :** [Temagoul Samy & Pinel Raoul]  
**Date :** Septembre 2025  

## Résumé
Ce script bash permet d’automatiser la gestion de machines virtuelles sous VirtualBox.  
Il offre la possibilité de créer, lister, supprimer, démarrer et arrêter des VM, tout en ajoutant des métadonnées (date de création, propriétaire).  
Les VM créées sont configurées pour booter en PXE et disposent d’un disque et d’une RAM paramétrables.

---

## Prérequis
- VirtualBox installé avec la commande `VBoxManage` accessible dans le PATH.  
- Script exécutable :  
  ```bash
  chmod +x genMV.sh
  ```

---

## Usage
```bash
./genMV.sh [ACTION] [Nom_VM] [RAM_MiB] [DISK_GiB]
```

### Actions disponibles
- `L` : Liste toutes les VM avec leurs métadonnées (date de création, propriétaire).
- `N <Nom_VM> <RAM_MiB> <DISK_GiB>` : Crée une nouvelle VM (Debian 64 bits) avec la RAM et le disque spécifiés.  
  - Boot configuré sur PXE.  
  - Ajout automatique de métadonnées.
- `S <Nom_VM>` : Supprime la VM et son disque.
- `D <Nom_VM>` : Démarre la VM.
- `A <Nom_VM>` : Arrête la VM.

---

## Exemple d’utilisation
- Créer une VM appelée `TestVM` avec 2 Go de RAM et 20 Go de disque :
  ```bash
  ./genMV.sh N TestVM 2048 20
  ```

- Lister toutes les VM et leurs métadonnées :
  ```bash
  ./genMV.sh L
  ```

- Démarrer la VM `TestVM` :
  ```bash
  ./genMV.sh D TestVM
  ```

- Supprimer la VM `TestVM` :
  ```bash
  ./genMV.sh S TestVM
  ```

---
