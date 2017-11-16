VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
 config.ssh.username = "vagrant"
 config.ssh.password = "vagrant"

# CentOS7 - OpenStack SaltStack formulas - controller
$install_script_controller = <<SCRIPT
/vagrant/provision/run.sh
SCRIPT
 config.vm.define "controller" do |controller|
   controller.vm.provision :shell, inline: $install_script_controller
   controller.vm.box = "centos74-base"
   controller.vm.network :private_network, ip: "192.168.100.151"
   controller.vm.network :private_network, ip: "192.168.101.151"
   controller.vm.hostname = "controller"
   controller.vm.provider :virtualbox do |vb|
     vb.name = "vagrant-controller"
     vb.gui = false
     vb.customize ["modifyvm", :id, "--memory", "3500"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
   end
 end

# CentOS7 - OpenStack SaltStack formulas - compute
$install_script_compute = <<SCRIPT
/vagrant/provision/run.sh
SCRIPT
 config.vm.define "compute" do |compute|
   compute.vm.provision :shell, inline: $install_script_compute
   compute.vm.box = "centos74-base"
   compute.vm.network :private_network, ip: "192.168.100.152"
   compute.vm.network :private_network, ip: "192.168.101.152"
   compute.vm.hostname = "compute"
   compute.vm.provider :virtualbox do |vb|
     vb.name = "vagrant-compute"
     vb.gui = false
     vb.customize ["modifyvm", :id, "--memory", "1024"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
   end
 end

# CentOS7 - OpenStack SaltStack formulas - block
$install_script_block = <<SCRIPT
/vagrant/provision/run.sh
SCRIPT
 config.vm.define "block" do |block|
   block.vm.provision :shell, inline: $install_script_block
   block.vm.box = "centos74-base"
   block.vm.network :private_network, ip: "192.168.100.153"
   block.vm.network :private_network, ip: "192.168.101.153"
   block.vm.hostname = "block"
   block.vm.provider :virtualbox do |vb|
     vb.name = "vagrant-block"
     vb.gui = false
     vb.customize ["modifyvm", :id, "--memory", "1024"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
     line = `VBoxManage list systemproperties | grep "Default machine folder"`
     vb_machine_folder = line.split(':')[1].strip()
     second_disk = File.join(vb_machine_folder, vb.name, 'disk2.vdi')
     unless File.exist?(second_disk)
       vb.customize ['createhd', '--filename', second_disk, '--format', 'VDI', '--size', 10 * 1024]
     end
     vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', second_disk]
   end
 end

# CentOS7 - OpenStack SaltStack formulas - object
$install_script_object = <<SCRIPT
/vagrant/provision/run.sh
SCRIPT
 config.vm.define "object" do |object|
   object.vm.provision :shell, inline: $install_script_object
   object.vm.box = "centos74-base"
   object.vm.network :private_network, ip: "192.168.100.154"
   object.vm.network :private_network, ip: "192.168.101.154"
   object.vm.hostname = "object"
   object.vm.provider :virtualbox do |vb|
     vb.name = "vagrant-object"
     vb.gui = false
     vb.customize ["modifyvm", :id, "--memory", "1024"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
     line = `VBoxManage list systemproperties | grep "Default machine folder"`
     vb_machine_folder = line.split(':')[1].strip()
     second_disk = File.join(vb_machine_folder, vb.name, 'disk2.vdi')
     unless File.exist?(second_disk)
       vb.customize ['createhd', '--filename', second_disk, '--format', 'VDI', '--size', 10 * 1024]
     end
     vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', second_disk]
   end
 end

end
