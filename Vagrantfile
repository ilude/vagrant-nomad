Dir[File.expand_path("#{File.dirname(__FILE__)}/plugins/*.rb")].each {|file| require file }
env = UserEnv.load

Vagrant.configure(2) do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.network :public_network, bridge: env['switch_name']
  config.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: env['smb_username'], smb_password: env['smb_password']
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"

  config.vm.provider "hyperv" do |h|
    h.memory = "1024"
    h.linked_clone = true
  end

  config.trigger.before :up do |trigger|
    trigger.info = "cleaning up consul-server files..."
    ['consul-server.ip', 'consul-server.key'].each do |file|
      File.delete(file) if File.exist?(file)
    end
  end

  config.vm.provision "shell", path: "./setup.sh", privileged: false

  (1..3).each do |i|
    config.vm.define "server-#{i}" do |node|
      node.vm.hostname = "server-#{i}"
      #node.vm.provision "shell", path: "./consul-server.sh", privileged: false
    end
  end

end