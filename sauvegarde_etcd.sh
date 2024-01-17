#!/bin/bash

# Activer le mode de débogage
set -x

# Chemin vers les certificats ETCD
ETCD_CERT_DIR="$HOME/etcd-certs"
echo "Chemin des certificats ETCD: $ETCD_CERT_DIR"

# Nom du fichier de sauvegarde basé sur la date et l'heure actuelles
BACKUP_FILE_NAME="etcd-backup-$(date +%Y%m%d%H%M%S).db"
echo "Nom du fichier de sauvegarde: $BACKUP_FILE_NAME"

# Emplacement pour stocker les sauvegardes ETCD dans le répertoire personnel de l'utilisateur
BACKUP_DIR="$HOME/etcd-backups"
echo "Répertoire de sauvegarde: $BACKUP_DIR"

# Création du répertoire de sauvegarde s'il n'existe pas.
mkdir -p "$BACKUP_DIR"
echo "Répertoire de sauvegarde créé (ou déjà existant)."

# Commande de sauvegarde ETCD
echo "Début de la sauvegarde ETCD..."
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cert="${ETCD_CERT_DIR}/server-client.crt" \
  --key="${ETCD_CERT_DIR}/server-client.key" \
  --cacert="${ETCD_CERT_DIR}/server-ca.crt" \
  snapshot save "${BACKUP_DIR}/${BACKUP_FILE_NAME}"

# Vérifier si la sauvegarde a réussi
if [[ $? -eq 0 ]]; then
  echo "Sauvegarde ETCD effectuée avec succès: ${BACKUP_FILE_NAME}"
else
  echo "La sauvegarde ETCD a échoué."
  exit 1
fi

# Désactiver le mode de débogage
set +x