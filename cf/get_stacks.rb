require File.expand_path(File.dirname(__FILE__) + '/../config')

stackname = ARGV.first
unless stackname
  puts "Usage: get_stacks.rb <STACKNAME>"
  exit 1
end

cfm = AWS::CloudFormation.new
stack = cfm.stacks[stackname]
# enumerating all resources for a stack
stack.resources.each do |resource|
  puts resource.resource_type #+ " " + resource.logical_resource_id
  puts resource.description
#  puts resource.last_updated_timestamp
  puts resource.logical_resource_id
#  puts resource.metadata
#  puts resource.resource_status
#  puts resource.resource_status_reason
  puts resource.stack
  puts resource.stack_id
  puts resource.stack_name
end
#stack.resource_summaries.each do |summary|
#    puts "#{summary[:physical_resource_id]}"
#    puts "#{summary[:resource_status]}"
#    puts "#{summary[:logical_resource_id]}"
#    puts "#{summary[:physical_resource_id]}"
#    puts "#{summary[:resource_type]}"
#    puts "#{summary[:resource_status]}"
#    puts "#{summary[:resource_status_reason]}"
#    puts "#{summary[:last_updated_timestamp]}"
#end
