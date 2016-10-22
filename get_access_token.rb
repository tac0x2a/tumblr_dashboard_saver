#!/usr/bin/env ruby

require 'oauth'
require 'json'

TokenFile = "oauth_token.json"
ConsumerKeysFile = "consumer_keys.json"

# Todo: Edit consumer key and secret values in ConsumerKeysFile.
consumer_keys = JSON.parse(File.read(ConsumerKeysFile))

ConsumerKey    = consumer_keys["consumer_key"].strip
ConsumerSecret = consumer_keys["consumer_secret"].strip

consumer = OAuth::Consumer.new( ConsumerKey,ConsumerSecret,
 {
     :site => "http://www.tumblr.com",
     :request_token_path => "/oauth/request_token",
     :access_token_path => "/oauth/access_token",
     :authorize_path => "/oauth/authorize"
 }
)

puts "Requesting..."
begin
  request_token = consumer.get_request_token(exclude_callback: true)
rescue => r
  puts "Failed to Getting request token. Check your ConsumerKey and SECRET key in consumer.json"
  exit
end

print <<-EOB
1. Open this link and arraw to access.

  #{request_token.authorize_url}

2. Copy oauth_verifier and paste here
EOB
print ">"

oauth_verifier = gets.strip
access_token = request_token.get_access_token(oauth_verifier: oauth_verifier)

tokens_as_json = {
  consumer_key:       ConsumerKey,
  consumer_secret:    ConsumerSecret,
  oauth_token:        access_token.token,
  oauth_token_secret: access_token.secret
}

# output
File.open(TokenFile, "w") do |fp|
  fp.puts tokens_as_json.to_json.to_s
end

puts "Finished. Access token is stored to #{TokenFile}."
puts "Please press Enterkey to exit."
puts gets
