require "json"
require "yaml"
require 'io/console'

class UserEnv
	def self.load
		instance = self.new
		instance.load_env
	end

	def env_file
		File.join(Dir.home, '.vagrant.d', 'vagrant.env')
	end

	def load_env
		return {} unless(Gem.win_platform? && ENV['VAGRANT_DEFAULT_PROVIDER'].eql?("hyperv"))
		
		#raise "No UserEnv file exists! Please run \"rake create:env\"" unless File.exists?(env_file)
    create_env_file unless File.exists?(env_file)

		default_env_config = {
		  'smb_username' => ENV['USERNAME'],
		  'switch_name' => "Vagrant Virtual Switch"
		}

		default_env_config.merge(YAML::load(File.read(env_file)))
	end

	def create_env_file
		return if File.exists?(env_file)

		settings = {}
		puts "Enter current password: "
		password = ::STDIN.noecho(&:gets)
		settings['smb_password'] = password.chomp

		get_switch_command = "Write-Host $(ConvertTo-JSON @(Get-VMSwitch | Select-Object Name,SwitchType,NetAdapterInterfaceDescription))"
		output =  `powershell.exe -ExecutionPolicy RemoteSigned -Command \"#{get_switch_command}\"`
		switches = JSON.parse(output)

		if switches.length > 1
          puts "Please choose a switch to attach to your Hyper-V instance: "
          switches.each_index do |i|
            puts "#{i+1}) #{switches[i]["Name"]}"
          end
          puts

          puts "What switch would you like to use? "
          switch = ::STDIN.gets
          switch = switch.chomp.to_i - 1
          settings['switch_name'] = switches[switch]["Name"]
        else
          settings['switch_name'] = switches[0]["Name"]
        end

		File.open(env_file, "w") do |file|
		  file.write settings.to_yaml
		end
	end
end