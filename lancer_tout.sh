#!/bin/bash

# Vérifier si le service k3s est actif
if ! systemctl is-active --quiet k3s; then
    echo "Le service k3s n'est pas actif. Démarrage en cours..."
    sudo systemctl start k3s
    sleep 5  # Attendre quelques secondes pour s'assurer que k3s démarre
fi

# Vérifier si k3s est correctement démarré
if ! systemctl is-active --quiet k3s; then
    echo "Échec du démarrage de k3s. Vérifiez les journaux pour plus de détails."
    exit 1
fi


# Arrête le script si une commande échoue
set -e

./deploy.sh
echo "Déploiement réussi."

./sauvegarde_etcd.sh
echo "Sauvegarde ETCD réussie."

./collecte_logs.sh
echo "Collecte des logs réussie."

./organiser_fichiers.sh
echo "Organisation des fichiers terminée."

# Supprimer l'archive existante si elle existe
rm -f kuber_exo.tar.gz

# Créer l'archive avec tous les fichiers nécessaires
tar -czvf kuber_exo.tar.gz *.yaml deploy.sh sauvegarde_etcd.sh collecte_logs.sh

# Ajouter les fichiers de logs et de sauvegarde s'ils existent
[[ -f etcd-backup-*.db ]] && tar -rvf kuber_exo.tar.gz etcd-backup-*.db
[[ -f fastapi-logs.txt ]] && tar -rvf kuber_exo.tar.gz fastapi-logs.txt
[[ -f postgres-logs.txt ]] && tar -rvf kuber_exo.tar.gz postgres-logs.txt
[[ -f pgadmin-logs.txt ]] && tar -rvf kuber_exo.tar.gz pgadmin-logs.txt

echo "Tous les processus ont été exécutés avec succès. Archive 'kuber_exo.tar.gz' prête."
