#!/usr/bin/env bash
set -euo pipefail

MASTER_IP=192.168.56.12
VAGRANT_KEY="/home/vagrant/.ssh/id_rsa"
KUBECONFIG_DIR="/home/vagrant/.kube"
KUBECONFIG_FILE="${KUBECONFIG_DIR}/config"

echo "[INFO] Installation de Helm sur VM1…"

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y

# Vérifier que la commande helm existe
if ! command -v helm &> /dev/null; then
  echo "Erreur : Helm n'est pas installé ou n'est pas dans le PATH." >&2
  exit 1
fi

# Afficher la version courte
echo "Version de Helm installée :"
helm version --short


echo "[INFO] Installation de kubectl sur VM1…"

# 1. Récupérer la dernière version stable de kubectl
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -L -o kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo "[OK] kubectl installé : version $KUBECTL_VERSION"

# 2. Préparer ~/.kube pour vagrant
sudo -u vagrant mkdir -p "$KUBECONFIG_DIR"
sudo chmod 700 "$KUBECONFIG_DIR"

# 3. Récupérer le kubeconfig via SSH en user vagrant avec sa clé
echo "[INFO] Récupération de /etc/rancher/k3s/k3s.yaml depuis $MASTER_IP…"
sudo -u vagrant ssh \
  -i "$VAGRANT_KEY" \
  -o StrictHostKeyChecking=no \
  vagrant@"$MASTER_IP" \
  "sudo cat /etc/rancher/k3s/k3s.yaml" \
  > "$KUBECONFIG_FILE"

# 4. Restreindre les permissions
sudo chmod 600 "$KUBECONFIG_FILE"
sudo chown vagrant:vagrant "$KUBECONFIG_FILE"

# 5. Adapter l’API server (127.0.0.1 → IP master)
sudo -u vagrant sed -i "s|127.0.0.1|${MASTER_IP}|g" "$KUBECONFIG_FILE"

# 6. Vérifier l’accès au cluster en user vagrant
echo "[INFO] Test de connexion au cluster Kubernetes…"
sudo -u vagrant KUBECONFIG="$KUBECONFIG_FILE" kubectl get nodes

echo "[SUCCESS] kubectl est prêt à être utilisé sur VM1 par l’utilisateur vagrant."
