require File.expand_path(File.dirname(__FILE__) + '/../config')
cfm = AWS::CloudFormation.new
cfm.stack_summaries.each do |summary|
    puts summary.to_yaml
end
# enumerating all resources for a stack
stack.resources.each do |resource|
  puts resource.resource_type + " " + resource.physical_resource_id
end
