set :application, "openstack"

set :user, 'demo'

set :ssh_options, { :forward_agent => true }

role :cpu,  "cpu.rcb.me"
role :infra, "dash.rcb.me"
role :puppet, "puppet.rcb.me"

namespace :puppet do
  desc "pull latests code from github to puppetmaster"
  task :pull, :roles => :puppet do
    run "cd /etc/puppet; sudo git pull"
  end
  
  desc "run puppet on hosts"
  task :kick, :roles => [:cpu, :infra] do
    run "sudo puppetd -t"
  end
  
  desc "pull and kick"
  task :up do
    pull
    kick
  end

end
