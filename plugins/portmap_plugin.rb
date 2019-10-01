require 'logger'

module VagrantPlugins
  class PortmapPlugin < Vagrant.plugin('2')
    name 'PortmapPlugin'
    description <<-DESC
        Some description of your plugin
    DESC

    [:machine_action_up, :machine_action_resume, :machine_action_reload, :machine_action_halt, :machine_action_destroy].each do |action|
      action_hook(:PortmapPlugin, action) do |hook|
        hook.prepend(VagrantPlugins::PortmapPlugin)
      end
    end

    attr_accessor :vm, :forwarded_ports, :logger

    def initialize(app, env)
      @app = app
      @env = env
      @vm  = env[:vm] || env[:machine]
      @forwarded_ports = env[:machine].config.vm.networks.select {|n| n.first.eql?(:forwarded_port) && !n[1][:id].eql?("ssh")}.map { |f| f[1] }
      @logger = ::Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, progname, msg|
         "    portmap: #{msg}\n"
      end
    end

    def call(env)
      action  = env[:action_name]
      if Gem.win_platform? && [:machine_action_halt, :machine_action_destroy, :machine_action_reload].include?(action)
        unmap_ports(env)
      end

      @app.call(env)

      if Gem.win_platform? && [:machine_action_up, :machine_action_resume, :machine_action_reload].include?(action)
        map_ports(env)
      end

      rescue => e
        vm.env.ui.error e.message
    end

    def map_ports(env)
      # Try to get the IP
      guest_ip = env[:machine].provider.driver.read_guest_ip["ip"]

      forwarded_ports.each do |f|
        host_port = f[:host]
        guest_port = f[:guest]
        logger.debug "Mapping localhost:#{host_port} to #{guest_ip}:#{guest_port}"
        %x[netsh interface portproxy add v4tov4 protocol=tcp listenport = #{host_port} listenaddress=localhost connectport = #{guest_port} connectaddress = #{guest_ip}]
      end
    end

    def unmap_ports(env)
      forwarded_ports.each do |f|
        port = f[:host]
        logger.debug "Unmapping Port #{port}"
        %x[netsh.exe interface portproxy delete v4tov4 protocol=tcp listenport=#{port} listenaddress=localhost]
      end
    end
  end
end
