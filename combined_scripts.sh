
# agg_script.sh

#!/bin/bash

# Répertoire où se trouve ce script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Fichier de sortie
output_file="${script_dir}/combined_scripts.sh"

# Vider/Créer le fichier de sortie
> "$output_file"

# Boucle sur chaque script dans le répertoire
for script in "$script_dir"/*; do
    # Vérifier si le fichier est un fichier régulier et n'est pas le fichier de sortie
    if [ -f "$script" ] && [ "$script" != "$output_file" ]; then
        # Extraire le nom du fichier
        filename=$(basename "$script")
        # Ajouter le titre et le contenu du script au fichier de sortie
        echo -e "\n# $filename\n" >> "$output_file"
        cat "$script" >> "$output_file"
    fi
done

# collecte_logs.sh

#!/bin/bash

# Fonction pour collecter les logs d'une application donnée
collecter_logs() {
    local app_label=$1
    local log_file_prefix=$2
    local pod_names=$(kubectl get pods -l app=$app_label -o jsonpath="{.items[*].metadata.name}")

    for pod in $pod_names; do
        echo "Collecte des logs pour le pod $pod"
        kubectl logs $pod > "${log_file_prefix}_${pod}.txt"
    done
}

# Collecter les logs pour chaque application
collecter_logs "fastapi" "fastapi-logs"
collecter_logs "postgres" "postgres-logs"
collecter_logs "pgadmin" "pgadmin-logs"

echo "Logs collectés"

# deploy.sh

#!/bin/bash

# Création des déploiements et services
kubectl apply -f fastapi-deployment.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f pgadmin-deployment.yaml

kubectl apply -f fastapi-service.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f pgadmin-service.yaml

# Création du PVC
kubectl apply -f postgres-pvc.yaml

# Création de l'HPA
kubectl apply -f fastapi-hpa.yaml

echo "Déploiement terminé avec succès"

# Dockerfile

FROM python:3.9

WORKDIR /code

# Copie des dépendances
COPY ./requirements.txt /code/requirements.txt

# Installation des dépendances
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

# Copie des fichiers de l'application
COPY ./app /code/app

# Commande pour démarrer l'application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]

# fastapi-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fastapi
  template:
    metadata:
      labels:
        app: fastapi
    spec:
      containers:
      - name: fastapi
        image: odhl/image-fastapi
        ports:
        - containerPort: 80

# fastapi-hpa.yaml

apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: fastapi-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fastapi-deployment
  minReplicas: 3
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70

# fastapi-ingress.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fastapi-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts:
        - site.enone.cloudns.biz
      secretName: fastapi-tls
  rules:
    - host: site.enone.cloudns.biz
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: fastapi-service
                port:
                  number: 80

# fastapi-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: fastapi-service
spec:
  selector:
    app: fastapi
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP

# lancer_tout.sh

#!/bin/bash

# Lancer le déploiement
./deploy.sh

# Sauvegarder la base de données ETCD
./sauvegarde_etcd.sh

# Collecter les logs
./collecte_logs.sh

# Organiser les fichiers pour l'envoi
./organiser_fichiers.sh

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

# letsencrypt-clusterissuer.yaml

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: eno.sec@gotmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx

# organiser_fichiers.sh

#!/bin/bash

# Création des répertoires
mkdir -p YAML-STANDARD HELM KUSTOMIZE

# Copie des fichiers YAML dans YAML-STANDARD
cp *.yaml YAML-STANDARD/

# (Les fichiers pour HELM et KUSTOMIZE doivent être ajoutés manuellement ou générés selon vos configurations spécifiques.)

# Création de l'archive
tar -czvf kuber_exo.tar.gz YAML-STANDARD HELM KUSTOMIZE

echo "Organisation des fichiers terminée et archivée dans kuber_exo.tar.gz"

# pgadmin-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgadmin-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pgadmin
  template:
    metadata:
      labels:
        app: pgadmin
    spec:
      containers:
      - name: pgadmin
        image: dpage/pgadmin4:latest
        env:
        - name: PGADMIN_DEFAULT_EMAIL
          value: admin@example.com
        - name: PGADMIN_DEFAULT_PASSWORD
          value: admin
        ports:
        - containerPort: 80

# pgadmin-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: pgadmin-service
spec:
  selector:
    app: pgadmin
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP

# postgres-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:latest
        env:
        - name: POSTGRES_PASSWORD
          value: password
        ports:
        - containerPort: 5432

# postgres-pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi

# postgres-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  type: ClusterIP

# requirements.txt

fastapi
uvicorn[standard]

# sauvegarde_etcd.sh

#!/bin/bash

NOM_FICHIER_SAUVEGARDE="etcd-backup-$(date +%Y%m%d%H%M%S).db"

# Remplacez la ligne suivante par votre commande réelle de sauvegarde ETCD
k3s etcd-snapshot save --name $NOM_FICHIER_SAUVEGARDE

echo "Sauvegarde ETCD effectuée: $NOM_FICHIER_SAUVEGARDE"
