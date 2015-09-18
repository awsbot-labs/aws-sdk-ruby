require File.expand_path(File.dirname(__FILE__) + '/../config')
require 'net/ssh'

(region, id, private_key) = ARGV
unless region && id && private_key
  puts "Usage: read_object.rb <REGION> <ID> <PRIVATE_KEY>"
  exit 1
end

# create a new instance of the ec2 interface
ec2 = AWS::EC2.new

# set region
if region = ARGV.first
  region = ec2.regions[region]
  unless region.exists?
    puts "Requested region '#{region.name}' does not exist.  Valid regions:"
    puts "  " + ec2.regions.map(&:name).join("\n  ")
    exit 1
  end

  # a region acts like the main EC2 interface
  ec2 = region
end

# create an instance object and check that it exists.
i = ec2.instances[id]
unless i.exists?
  puts "Instance #{id} does not exist"
  exit 1
end


begin
  Net::SSH.start(i.ip_address, "ec2-user",
                 :key_data => private_key) do |ssh|
    puts "Running 'uname -a' on the instance yields:"
    puts ssh.exec!("uname -a")
                 end
rescue SystemCallError, Timeout::Error => e
  # port 22 might not be available immediately after the instance finishes launching
  sleep 1
  retry
end
