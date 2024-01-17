#!/bin/bash

# Fonction pour collecter les logs d'une application donnée
collecter_logs() {
    local app_label=$1
    local log_file_prefix=$2
    local pod_names=$(kubectl get pods -l app=$app_label -o jsonpath="{.items[*].metadata.name}")

    for pod in $pod_names; do
        if kubectl get pod "$pod" &> /dev/null; then
            echo "Collecte des logs pour le pod $pod"
            kubectl logs $pod > "${log_file_prefix}_${pod}.txt"
        else
            echo "Pod $pod non trouvé."
        fi
    done
}

collecter_logs "fastapi" "fastapi-logs"
collecter_logs "postgres" "postgres-logs"
collecter_logs "pgadmin" "pgadmin-logs"

echo "Logs collectés"
