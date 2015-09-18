require File.expand_path(File.dirname(__FILE__) + '/../config')

DefinedTags = ['ProductKey','Owner','Service','Name','ContactEmail','Environment','ExpiryDate','Hostname','Notes','OperatingSystem','Role']
# Subset of DefinedTags which are deemed 'interesting' for EC2/RDS.
# Absence of any tag listed in InterestingXTags is flagged as an error.
InterestingEC2Tags = ['ProductKey','Owner','Service']
InterestingRDSTags = ['ProductKey','Owner']
# AWS tags that are of interest, plus column headings.
AWSTags = {'aws:autoscaling:groupName' => 'AutoScaling Group','aws:cloudformation:stack-name' => 'CloudFormation Stack','aws:elasticmapreduce:job-flow-id' => 'ElasticBeanstack Environment','elasticbeanstalk:environment-name' => 'ElasticMapReduce Flow'}

(region, id) = ARGV
unless region && id
  puts "Usage: get_instance.rb <REGION> <ID>"
  exit 1
end

# create a new instance of the rds interface
rds = AWS::RDS.new

# set region
if region = ARGV.first
  region = rds.regions[region]
  unless region.exists?
    puts "Requested region '#{region.name}' does not exist.  Valid regions:"
    puts "  " + rds.regions.map(&:name).join("\n  ")
    exit 1
  end

  # a region acts like the main EC2 interface
  rds = region
end

# create an instance object and check that it exists.
i = rds.instances[id]
unless i.exists?
  puts "Instance #{id} does not exist"
  exit 1
end

def filter_tags(tags, interesting_tags)
  aws_tags = Hash[tags.select {|k,v| AWSTags.keys.include?(k)}]
  # This might be making a large assumption...
  tags.reject! {|k,v| k.match(/:/)}
  defined_tags = Hash[tags.select {|k,v| DefinedTags.include?(k)}]
  undefined_tags = Hash[tags.reject {|k,v| DefinedTags.include?(k)}]
  tag_error = false
  if undefined_tags.size > 0
    puts "Error, undefined tags exist on this instance."
    tag_error ||= (undefined_tags.size > 0)
  end
  if (interesting_tags - defined_tags.keys).size > 0
    puts "Tags on this instance have not been set correctly."
    tag_error ||= ((interesting_tags - defined_tags.keys).size > 0)
  end
  return tag_error, aws_tags, defined_tags, undefined_tags
end

tag_error,aws_tags,defined_tags,undefined_tags=filter_tags(i.tags.to_h,InterestingEC2Tags)

puts "Tag error? #{tag_error}"

puts "AWS tags:"
  aws_tags.each_pair do |tag_name,tag_value|
    puts "  #{tag_name} - #{tag_value}"
end

puts "Defined tags:"
  defined_tags.each_pair do |tag_name,tag_value|
    puts "  #{tag_name} - #{tag_value}"
end

puts "Undefined tags:"
  undefined_tags.each_pair do |tag_name,tag_value|
    puts "  #{tag_name} - #{tag_value}"
end
