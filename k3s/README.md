
# Kubernetes K3S

Un cluster kubernetes K3S composé de deux machines virtuelles sous l'OS Ubuntu 24.04 sera installé. `VM2` *(node controleur)* et `VM3` *(node agent)*.

### 1. Déploiement de K3S via un playbook ansible

L'action est à réaliser sur `VM1` depuis le répertoire personnel de vagrant.

```bash
vagrant ssh VM1
```

```bash
ansible-playbook /vagrant/ansible/playbooks/k3s-deploiement.yaml
```

Il faut compter en moyenne environ **`5 minutes`** pour le deploiement du cluster kubernetes k3s.

Pour quitter une box vagrant taper *`exit`*.

### 2. Se connecter sur K3S node controleur

```bash
vagrant ssh VM2  # k3s node controleur
```

### 3. Tester le bon fonctionnement de k3s 

Les actions sont à réaliser sur `VM2` depuis le répertoire personnel de vagrant.

Verifier l'etat du service k3s :

```bash
systemctl status k3s
```

Pour quitter la commande taper *`q`*.

Lister tous les nœuds membres du cluster Kubernetes :

```bash
kubectl get nodes
```

Sortie attendu : 

```bash
NAME   STATUS   ROLES                  AGE   VERSION
vm2    Ready    control-plane,master   21m   v1.32.3+k3s1
vm3    Ready    <none>                 20m   v1.32.3+k3s1
```

Lister tous les pods de tous les namespaces du cluster :

```bash
kubectl get pods -A
```

Sortie attendu : 

```bash
NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
kube-system   coredns-ff8999cc5-jg7kr                   1/1     Running     0          22m
kube-system   helm-install-traefik-crd-xdwf7            0/1     Completed   0          22m
kube-system   helm-install-traefik-jhghj                0/1     Completed   2          22m
kube-system   local-path-provisioner-774c6665dc-tckd2   1/1     Running     0          22m
kube-system   metrics-server-6f4c6675d5-jk2pb           1/1     Running     0          22m
kube-system   traefik-67bfb46dcb-jhb6n                  1/1     Running     0          21m
```

### 4. Gestion du cluster kubernetes depuis `VM1`

Les actions sont à réaliser sur `VM1` depuis le répertoire personnel de vagrant.

Verifier l'etat du service k3s :

```bash
vagrant ssh VM1
```

```bash
sudo /vagrant/setup-helm-kubectl-vm1.sh
```
Le script est à executer une seule fois, lors de la première connexion sur `VM1`.

```bash
kubectl get nodes
```

Sortie attendu : 

```bash
NAME   STATUS   ROLES                  AGE   VERSION
vm2    Ready    control-plane,master   31m   v1.32.3+k3s1
vm3    Ready    <none>                 30m   v1.32.3+k3s1
```

Pour executer des commandes sur `VM2` mais depuis `VM1` : 

```bash
ansible k3s_controleur -a "kubectl get nodes"
```

### 5. Gestion du cluster kubernetes depuis sa machine 

Pour gerer le cluster k3s depuis sa machine, il faut recuperer sur le node controleur `VM2`, le fichier `kubeconfig` localisé à l'emplacement *`/etc/rancher/k3s/k3s.yaml`* contenant toutes les informations nécessaires à `kubectl` et le copier sur *`$HOME/.kube/config`*.

Dans le fichier *`$HOME/.kube/config`*, remplaces *`server: https://127.0.0.1:6443`* par *`server: https://192.168.56.12:6443`*


Verifier kubectl configuration depuis son terminal:

```bash
kubectl cluster-info
```

Sortie attendu : 

```bash
Kubernetes control plane is running at https://192.168.56.12:6443
CoreDNS is running at https://192.168.56.12:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://192.168.56.12:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

```


Lister tous les nœuds membres du cluster Kubernetes depuis sa machine :

```bash
kubectl get nodes
```

Pour **`kubectl autocompletion`** consulter la documentation [ici](https://kubernetes.io/docs/reference/kubectl/quick-reference/#kubectl-autocomplete).


### 6. Deployer une application web de test `web-app`

Les actions sont à réaliser depuis ta machine.

Ouvres une fenêtre du Terminal et executes la commande ci-dessous depuis le répertoire `devops` du projet :

```bash
kubectl apply -f k3s/web-app.yaml
```

Verifies l'état de l'ensemble des objets déployés :

```bash
kubectl get all
```

Sortie attendu : 

```bash
NAME                           READY   STATUS    RESTARTS   AGE
pod/web-app-5865ff765f-ndpmp   1/1     Running   0          44s

NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
service/kubernetes   ClusterIP      10.43.0.1     <none>           443/TCP        69m
service/web-app      LoadBalancer   10.43.54.85   192.168.56.241   80:32739/TCP   44s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-app   1/1     1            1           44s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/web-app-5865ff765f   1         1         1       44s

```

Testes l'accessibilité de test `wep-app` depuis ton navigateur web :

**[http://192.168.56.241](http://192.168.56.241)**

### 7. Supprimer l'application web de test `web-app`

Les actions sont à réaliser depuis ta machine.

Ouvres une fenêtre du Terminal et executes la commande ci-dessous depuis le répertoire `devops` du projet :

```bash
kubectl delete -f k3s/web-app.yaml
```

Verifies la suppression de l'ensemble des objets :

```bash
kubectl get all
```

### 8. Deployer l'application web de `quiz`

Les actions sont à réaliser depuis ta machine.

Ouvres une fenêtre du Terminal et executes la commande ci-dessous depuis le répertoire `devops` du projet :

```bash
kubectl apply -f k3s/quiz-app.yaml
```

Verifies l'état de l'ensemble des objets déployés :
s
```bash
kubectl get all
```

Sortie attendu : 

```bash
NAME                            READY   STATUS    RESTARTS   AGE
pod/quiz-app-74cfd9c449-mlpdv   1/1     Running   0          4m2s

NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
service/kubernetes     ClusterIP      10.43.0.1      <none>           443/TCP        12d
service/quiz-service   LoadBalancer   10.43.97.161   192.168.56.241   80:32364/TCP   4m2s

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/quiz-app   1/1     1            1           4m2s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/quiz-app-74cfd9c449   1         1         1       4m2s

```

Testes l'accessibilité de `quiz-app` depuis ton navigateur web :

**[http://192.168.56.241](http://192.168.56.241)**

---

## 📚 Pour aller plus loin

- [Documentation Kubernetes](https://www.docker.com/)
- [Documentation K3S](https://k3s.io/)
- [DevOps Lab](../README.md)


