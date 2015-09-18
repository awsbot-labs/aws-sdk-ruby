#!/usr/bin/env ruby
## Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require File.expand_path(File.dirname(__FILE__) + '/../config')

require 'net/http'
require 'net/ssh'

instance = key_pair = group = nil
time = Time.now.freeze.to_i

def prompt(*args)
  print(*args)
  gets
end

begin
  ec2 = AWS::EC2.new

  # optionally switch to a non-default region
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
  puts "Filtering ec2 for image with the following attributes:"
  puts "root-device-type: ebs"

  # find the latest 64-bit EBS Amazon Linux AMI
  image = AWS.memoize do
    amazon_linux = ec2.images.with_owner("amazon").
      filter("root-device-type", "ebs").
      filter("architecture", "x86_64").
      filter("name", "amzn-ami*")

    # this only makes one request due to memoization
    amazon_linux.to_a.sort_by(&:name).last
  end
  puts "Using AMI: #{image.id}"

  # generate a key pair
  key_pair = ec2.key_pairs.create("#{image.id}-#{time}")
  puts "Generated keypair #{key_pair.name}, fingerprint: #{key_pair.fingerprint}"
  puts "Writing private key to file ./#{key_pair.name}"
  private_key = File.new(key_pair.name, "w")
  private_key.write(key_pair.private_key)
  private_key.chmod(0600)
  private_key.close

  # open SSH access
  group = ec2.security_groups.create("#{image.id}-#{time}")
  group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
  group.authorize_ingress(:tcp, 80, "0.0.0.0/0")
  group.authorize_ingress(:tcp, 443, "0.0.0.0/0")
  puts "Using security group: #{group.name}"

  # Set the type
  instance_type = 't1.micro'

  # Set the userdata
  user_data = File.open('user-data', 'r') { |file| file.read }

  # Tags
#  puts "Please enter the following tags:"
#  tags_list = ["Name","Service","Owner","Hostname","ContactEmail","ExpiryDate","Notes","ProductKey"]
#  tags = Hash.new
#  tags_list.each do |k|
#    v = prompt "#{k}: "
#    tags[k]=v
#  end

  # launch the instance
  puts "Launching instance #{image.id}-#{time}"
  instance = image.run_instance(:key_pair => key_pair,
                               :security_groups => group,
                               :instance_type => instance_type,
                               :user_data => user_data)
  sleep 10 while instance.status == :pending
  puts "Launched instance #{instance.id}, status: #{instance.status}"
  exit 1 unless instance.status == :running
#  tags.each do |k,v|
#    instance.add_tag(k, :value => v)
#  end

  begin
    Net::SSH.start(instance.ip_address, "ec2-user",
                   :key_data => [key_pair.private_key]) do |ssh|
      puts "Running 'uname -a' on the instance yields:"
      puts ssh.exec!("uname -a")
                   end
  rescue SystemCallError, Timeout::Error => e
    # port 22 might not be available immediately after the instance finishes launching
    sleep 1
    retry
  end
puts "Use the following command to login:"
puts "ssh -i #{key_pair.name} ec2-user@#{instance.dns_name}"
end
