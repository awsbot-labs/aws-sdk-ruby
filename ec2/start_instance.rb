require File.expand_path(File.dirname(__FILE__) + '/../config')

(region, id) = ARGV
unless region && id
  puts "Usage: read_object.rb <REGION> <ID>"
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

# Start the instance
if i.status == :running 
  puts "#{i.id} is already running"
  exit 1
else
  i.start
  sleep 10 while i.status == :pending
  puts "Started instance #{i.id}, status: #{i.status}"
end

# Print all instance attributes
puts "AMI launch index:                     #{i.ami_launch_index}"
puts "API termination disabled:             #{i.api_termination_disabled?}"
puts "Architecture:                         #{i.architecture}"
puts "Client token:                         #{i.client_token}"
puts "DNS name:                             #{i.dns_name}"
puts "Hypervisor:                           #{i.hypervisor}"
puts "IAM instance profile arn:             #{i.iam_instance_profile_arn}"
puts "IAM instance profile id:              #{i.iam_instance_profile_id}"
puts "ID:                                   #{i.id}"
puts "Image ID:                             #{i.image_id}"
puts "Instance initiated shutdown behavior: #{i.instance_initiated_shutdown_behavior}"
puts "Instance type:                        #{i.instance_type}"
puts "IP address:                           #{i.ip_address}"
puts "Kernal ID:                            #{i.kernel_id}"
puts "Key name:                             #{i.key_name}"
puts "Launch time:                          #{i.launch_time}"
puts "Monitoring:                           #{i.monitoring}"
puts "Owner:                                #{i.owner_id}"
puts "Platform:                             #{i.platform}"
puts "Private DNS name:                     #{i.private_dns_name}"
puts "Private IP address:                   #{i.private_ip_address}"
puts "Ramdisk:                              #{i.ramdisk_id}"
puts "Requestor ID:                         #{i.requester_id}"
puts "Reservation ID:                       #{i.reservation_id}"
puts "Root device name:                     #{i.root_device_name}"
puts "Root device type:                     #{i.root_device_type}"
puts "State transition reason:              #{i.state_transition_reason}"
puts "Status:                               #{i.status}"
puts "Status code:                          #{i.status_code}"
puts "Subnet ID:                            #{i.subnet_id}"
puts "User data:                            #{i.user_data}"
puts "Virtualization type:                  #{i.virtualization_type}"
puts "VPC ID:                               #{i.vpc_id}"
