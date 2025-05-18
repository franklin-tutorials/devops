
# Machines virtuelles avec Vagrant

[Vagrant](https://developer.hashicorp.com/vagrant) est un outil qui permet de `créer, configurer et gérer des machines virtuelles de manière automatisée` à l’aide de simples fichiers de configuration.

Plus besoin d’installer manuellement des serveurs ou des outils, Vagrant le fait pour toi à partir d’un simple fichier : `Vagrantfile`.


### Exemple de Vagrantfile

```bash
Vagrant.configure("2") do |config|

  # Box de base
  config.vm.box = "bento/ubuntu-24.04"

  # Liste des machines avec ressources personnalisées
  machines = [
    { name: "VM1", ip: "192.168.56.11", memory: 1024, cpus: 1 },
    { name: "VM2", ip: "192.168.56.12", memory: 1024, cpus: 1 },
    { name: "VM3", ip: "192.168.56.13", memory: 1024, cpus: 1 }
  ]

  # Boucle de création des VMs
  machines.each_with_index do |machine, index|
    config.vm.define machine[:name] do |node|
      node.vm.hostname = machine[:name].downcase
      node.vm.network "private_network", ip: machine[:ip]
      node.vm.network "forwarded_port", guest: 22, host: (2221 + index), id: "ssh"
      node.vm.provider "virtualbox" do |vb|
        vb.name = machine[:name]
        vb.memory = machine[:memory]
        vb.cpus = machine[:cpus]
      end
    end
  end

end
```

Avec ce fichier, tu peux lancer 3 machines virtuelles Ubuntu avec :

```bash
vagrant up 
```

Et les détruire avec :

```bash
vagrant destroy
```

Vagrant utilise souvent `VirtualBox`, `VMware` ou `Hyper-V` comme backend pour exécuter les machines virtuelles.

---

## 📚 Pour aller plus loin

- [Documentation Vagrant](https://developer.hashicorp.com/vagrant)
- [DevOps Lab](../README.md)


