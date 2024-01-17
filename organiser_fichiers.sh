#!/bin/bash

# Création des répertoires
mkdir -p YAML-STANDARD HELM KUSTOMIZE

# Copie des fichiers YAML dans YAML-STANDARD
cp *.yaml YAML-STANDARD/

# (Les fichiers pour HELM et KUSTOMIZE doivent être ajoutés manuellement ou générés selon vos configurations spécifiques.)

# Création de l'archive
tar -czvf kuber_exo.tar.gz YAML-STANDARD HELM KUSTOMIZE

echo "Organisation des fichiers terminée et archivée dans kuber_exo.tar.gz"
