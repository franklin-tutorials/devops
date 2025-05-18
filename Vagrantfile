# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # ────────────────────────────────────────────────────────────────────────────
  # 1) Déclarez ici vos VMs “cibles” (VM2 & VM3) avec type de box, ip, mémoire et CPUs
  # ────────────────────────────────────────────────────────────────────────────
  machines = [
    { name: "VM2", box: "bento/ubuntu-24.04",     ip: "192.168.56.12", memory: 1024, cpus: 1 },
    { name: "VM3", box: "bento/ubuntu-24.04", ip: "192.168.56.13", memory: 3096, cpus: 2 }
  ]

  machines.each_with_index do |machine, idx|
    config.vm.define machine[:name] do |node|
      node.vm.box      = machine[:box]
      node.vm.hostname = machine[:name].downcase

      # Réseau privé en IP fixe
      node.vm.network "private_network", ip: machine[:ip]

      # SSH direct depuis l'hôte : ports 2222, 2223…
      node.vm.network "forwarded_port",
                      guest: 22,
                      host:  2222 + idx,
                      id:    "ssh"

      # Personnalisation mémoire & CPU
      node.vm.provider "virtualbox" do |vb|
        vb.name   = machine[:name]
        vb.memory = machine[:memory]
        vb.cpus   = machine[:cpus]
      end
    end
  end

  # ────────────────────────────────────────────────────────────────────────────
  # 2) Déclaration de VM1 (control node) avec trigger pour lever VM2 & VM3 avant
  # ────────────────────────────────────────────────────────────────────────────
  config.vm.define "VM1" do |node|
    node.vm.box      = "bento/ubuntu-24.04"
    node.vm.hostname = "vm1"
    node.vm.network "private_network", ip: "192.168.56.11"
    node.vm.network "forwarded_port",
                    guest: 22,
                    host:  2221,
                    id:    "ssh"
    node.vm.provider "virtualbox" do |vb|
      vb.name   = "VM1"
      vb.memory = 1024
      vb.cpus   = 1
    end

    # Avant de lancer VM1, on s’assure que VM2 & VM3 sont prêtes
    node.trigger.before :up do |t|
      t.info = " Démarrage préalable de VM2 & VM3"
      t.run  = { inline: "vagrant up VM2 VM3 --no-parallel" }
    end

    # Provisionnement de VM1 après que VM2 & VM3 sont up
    node.vm.provision "shell", path: "provision_vm1.sh"
  end

end
