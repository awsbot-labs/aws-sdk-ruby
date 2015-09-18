require File.expand_path(File.dirname(__FILE__) + '/../config')

(bucket_name, key) = ARGV
unless bucket_name && key
  puts "Usage: download_object.rb <BUCKET_NAME> <KEY>"
  exit 1
end

# create a new instance of the S3 interface
s3 = AWS::S3.new

# open the specified file from the bucket
b = s3.buckets[bucket_name]
o = b.objects[key]

# Print information about the object
puts "Key: #{key}"
puts "Bucket: #{o.bucket}"
puts "Public URL: #{o.public_url}"
puts "Content length: #{o.content_length}"
puts "Content type: #{o.content_type}"
puts "Exists: #{o.exists?}"
puts "Etag: #{o.etag}"
puts "Metadata: #{o.metadata}"
puts "Last modified: #{o.last_modified}"
puts "ACL: #{o.acl}"

# Create a file using the Etag as the name and write the contents of the file to it.
File.open("#{o.etag}.txt", 'w') do |file|
  o.read do |chunk|
     file.write(chunk)
  end
end
