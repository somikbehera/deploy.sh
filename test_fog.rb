#!/usr/bin/ruby

require 'rubygems'
require 'fog'

test_name = "Test Run #{Time.now}"

# Get your api key / token `keystone-mange token list`
compute = Fog::Compute.new(:provider => 'Rackspace',
                           :rackspace_auth_token => '999888777666',
                           :rackspace_management_url => 'http://10.4.99.1:8774/v1.0/',
                           :rackspace_username => 'admin',
                           :rackspace_api_key =>  'admin')

servers = compute.servers
puts "Found #{servers.length} servers"

servers.each do |server|
  if server.name.start_with?("Test Run") and server.ready?
    puts " > killing #{server.name}"
    server.destroy rescue nil
  end
end

flavors = compute.flavors

smallest_flavor = flavors.sort_by(&:ram).first
puts "Found #{flavors.length} flavors"
puts flavors.collect{|x| "> #{x.name}"}.join("\n")
puts "Smallest flavor has #{smallest_flavor.ram} RAM " +
     "and #{smallest_flavor.disk} disk"
puts

images = compute.images
first_ami = images.detect{ |x| x.name =~ /^ami-/ }
puts "Found #{images.length} images"
images.each { |i| puts "> #{i.name}" }
puts "Using AMI-type image #{first_ami.name}"
puts

servers = compute.servers
puts "Found #{servers.length} servers"
(40 - servers.size).times do
  server = compute.servers.new(:flavor_id => smallest_flavor.id,
                               :image_id => first_ami.id,
                               :name => test_name)

  server.personality = [ 
    {
      'path' => 'security_groups',
      'contents' => 'hi,by'
    },
    {
      'path' => 'key_name',
      'contents' => 'test'
    }
  ]
  server.save

  puts "launched #{server.name}"
  sleep(0.1)
end

sleep(4)

servers = compute.servers
puts "Found #{servers.length} servers"
servers.each { |x| puts " #{x.state} > #{x.name}" }
