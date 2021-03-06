begin
  require 'capistrano_colors'
rescue Object => e
  puts "sudo gem install capistrano_colors # for colours"
end

set :application, "openstack"

set :user, 'demo'

set :ssh_options, { :forward_agent => true }
set :use_sudo, true

if ENV['REAL']
  role :cpu, "10.4.99.2", "10.4.99.3", "10.4.99.4", "10.4.99.5", "10.4.99.6"
  role :infra, "10.4.99.1"
  role :puppet, "10.4.99.1"
else
  role :cpu,  "cpu.rcb.me"
  role :infra, "dash.rcb.me"
  role :puppet, "puppet.rcb.me"
end

namespace :puppet do
  desc "pull latests code from github to puppetmaster"
  task :pull, :roles => :puppet do
    run "cd /etc/puppet; sudo git pull"
  end
  
  desc "run puppet on hosts"
  task :kick, :roles => [:cpu, :infra] do
    sudo "apt-get update"
    sudo "puppetd -t"
  end
  
  desc "pull and kick"
  task :up do
    pull
    kick
  end

end

namespace :instance do
  desc "list of instances"
  task :list, :roles => :cpu do
    sudo "virsh list"
  end
  
  desc "information about VM - can specify ID via environment"
  task "info", :roles => :cpu do
    instance_id = ENV['ID'] || Capistrano::CLI.ui.ask('Instance ID?')
    hex = instance_id.to_i.to_s(16)
    name = "instance-#{'0'*(8-hex.size)+hex}"
    puts "="*80
    run "ls -al /var/lib/nova/instances/#{name}"
    puts "="*80
    sudo "cat /var/log/libvirt/qemu/#{name}.log"
    puts "="*80
    sudo "virsh list | grep #{name}"
  end
  
end