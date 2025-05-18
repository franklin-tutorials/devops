#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# Provisionnement de VM1 (Control Node Ansible)
# Installe Ansible (version paramétrable) via pip en enlevant la
# protection PEP 668, ainsi que sshpass, git et netcat.
# ------------------------------------------------------------------

# 0. Variable de version
ANSIBLE_VERSION="11.5.0"

echo "[INFO] Début du provisioning sur VM1…"
echo "[INFO] Installation d'Ansible ${ANSIBLE_VERSION}"

# 1. Installer Python3, pip3 et dépendances
if [ -f /etc/debian_version ]; then
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-pip sshpass git netcat-openbsd

elif [ -f /etc/redhat-release ]; then
  sudo dnf update -y || sudo yum update -y
  sudo dnf install -y python3 python3-pip sshpass nc git || \
    sudo yum install -y python3 python3-pip sshpass nc git

else
  echo "[ERREUR] OS non supporté." >&2
  exit 1
fi

# 2. Installation d'Ansible exactement en version ${ANSIBLE_VERSION}
#    en cassant volontairement la protection PEP 668
echo "[INFO] pip3 install ansible==${ANSIBLE_VERSION} --break-system-packages"
sudo pip3 install --upgrade --break-system-packages "ansible==${ANSIBLE_VERSION}"

echo "[OK] Ansible ${ANSIBLE_VERSION} installé (system-wide via pip)."

# 3. Génération de la paire SSH si besoin
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
  sudo -u vagrant mkdir -p /home/vagrant/.ssh
  sudo -u vagrant ssh-keygen -t rsa -b 4096 \
    -f /home/vagrant/.ssh/id_rsa -N ""
fi

# 4. Définition des cibles
TARGETS=( "192.168.56.12" "192.168.56.13" )

# 5. Attente de SSH
wait_for_ssh(){
  local ip=$1 timeout=300 waited=0
  until nc -z "$ip" 22; do
    (( waited+=5 ))
    [ $waited -ge $timeout ] && { echo "[ERREUR] $ip inaccessible."; exit 2; }
    sleep 5
  done
}
for ip in "${TARGETS[@]}"; do
  echo "[INFO] Attente SSH sur $ip…"
  wait_for_ssh "$ip"
done

# 6. Copie de la clé publique
PUBKEY=/home/vagrant/.ssh/id_rsa.pub
for ip in "${TARGETS[@]}"; do
  sshpass -p vagrant ssh-copy-id \
    -i "$PUBKEY" \
    -o StrictHostKeyChecking=no \
    vagrant@"$ip"
done

# 7. Remplissage de known_hosts
echo "[INFO] Ajout des empreintes dans known_hosts…"
sudo -u vagrant bash -c 'for ip in "${TARGETS[@]}"; do
  ssh-keyscan -H "$ip" >> /home/vagrant/.ssh/known_hosts
done'

# 8. Inventaire Ansible
sudo -u vagrant tee /home/vagrant/hosts > /dev/null <<EOF
[targets]
192.168.56.12 ansible_python_interpreter=/usr/bin/python3
192.168.56.13 ansible_python_interpreter=/usr/bin/python3
[k3s_controleur]
192.168.56.12 ansible_python_interpreter=/usr/bin/python3
[k3s_agent]
192.168.56.13 ansible_python_interpreter=/usr/bin/python3
EOF

# 9. Configuration pour taire les warnings
sudo -u vagrant tee /home/vagrant/ansible.cfg > /dev/null <<EOF
[defaults]
inventory = /home/vagrant/hosts
host_key_checking = False
interpreter_python = auto_silent
EOF

# 10. Désactivation de la vérif. hôte pour Ansible
export ANSIBLE_HOST_KEY_CHECKING=False

# 11. Test de connectivité
echo "[INFO] Test de ping Ansible avec la version $(ansible --version | head -n1)…"
sudo -u vagrant ansible -c local -i /home/vagrant/hosts targets -m ping -u vagrant

echo "[SUCCESS] Provisioning terminé !"
