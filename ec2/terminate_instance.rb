#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config')

(region, id) = ARGV
unless region && id
  puts "Usage: terminate_instance.rb <REGION> <ID>"
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
private_key = i.key_pair.name
puts "Terminating instance #{i.id}"
i.terminate
sleep 10 while i.status == :pending
if !i.exists?
  puts "Instance #{i.id} terminated"
end
File.delete(private_key)
puts "Private key deleted"
