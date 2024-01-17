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
