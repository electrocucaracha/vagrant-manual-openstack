# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  'vagrant_box'     => 'ubuntu/trusty64',
  'package-manager' => 'apt',
}

vd_conf = ENV.fetch('VD_CONF', 'etc/settings.yaml')
if File.exist?(vd_conf)
  require 'yaml'
  user_conf = YAML.load_file(vd_conf)
  conf.update(user_conf)
end


VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = conf['vagrant_box']

  config.vm.define :message_broker do |message_broker|
    message_broker.vm.hostname = 'message-broker'
    message_broker.vm.network :private_network, ip: '192.168.50.10'
    message_broker.vm.network :forwarded_port, guest: 5672 , host: 5672 
    message_broker.vm.provision "shell", path: conf['package-manager'] + "/rabbitmq.sh"
  end

  config.vm.define :database do |database|
    database.vm.hostname = 'database'
    database.vm.network :private_network, ip: '192.168.50.11'
    database.vm.network :forwarded_port, guest: 3306, host: 3306
    database.vm.provision "shell", path: conf['package-manager'] + "/mysql.sh"
  end

  config.vm.define :identity do |identity|
    identity.vm.hostname = 'identity'
    identity.vm.network :private_network, ip: '192.168.50.12'
    identity.vm.network :forwarded_port, guest: 5000, host: 5000
    identity.vm.network :forwarded_port, guest: 35357, host: 35357
    identity.vm.provision "shell", path: conf['package-manager'] + "/keystone.sh"
    #identity.vm.provision "shell", path: conf['package-manager'] + "/keystone_dev.sh"
  end

  config.vm.define :image do |image|
    image.vm.hostname = 'image'
    image.vm.network :private_network, ip: '192.168.50.13'
    image.vm.network :forwarded_port, guest: 9292, host: 9292
    image.vm.provision "shell", path: conf['package-manager'] + "/glance.sh"
    #image.vm.provision "shell", path: conf['package-manager'] + "/glance_dev.sh"
  end

end
