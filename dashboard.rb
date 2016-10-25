#!/usr/bin/env ruby

require "tumblr_client"

STDOUT.sync = true

def pickup(p)
  {
    "id" => p["id"],
    "image" => p["photos"].map{|ph| ph["alt_sizes"].min_by{|s| s["width"]}},
    "date" => p["date"]
  }
end

def save_dashboard(
  client, limit, since_id, my_blog_name,
  my_blog_img_dir = "MyBlogFiles",
  other_blog_img_dir = "OtherFiles")

  dashboard = client.dashboard({type:"photo", limit:20, since_id: since_id})

  posts = dashboard["posts"].reverse

  gp = posts.group_by{|p| p["blog_name"] == my_blog_name }
  my_posts     = (gp[true]  || []).map{|p| pickup(p)}
  others_posts = (gp[false] || []).map{|p| pickup(p)}



  Dir.mkdir(my_blog_img_dir) if not File.exists?(my_blog_img_dir)
  Dir.mkdir(other_blog_img_dir)  if not File.exists?(other_blog_img_dir)

  [my_blog_img_dir, other_blog_img_dir].zip([my_posts, others_posts]).each do |dir, posts|

    posts.each do |post|
      file_uri = post["image"].first["url"]
      ext = File.extname(file_uri)
      filename = post["id"].to_s + ext

      require 'open-uri'
      10.times do |t|
        begin
          dst_path = File.join(dir, filename)
          File.open( dst_path, "wb") do |dst|
            open(file_uri) do |src|
              dst.write(src.read)
            end
          end
          # success.
          puts "Saved #{dst_path} - #{post['date']}"

          break
        rescue => r
          # retry.
          p r
        end

        STDERR.puts("Failed to download #{file_uri}")
      end # of Retry (10.times do |t|)
    end # of posts
  end # of [MyBlogFiles, OtherFiles].zip([my_posts, others_posts]).each do

  posts.map{|p| p["id"]}.max
end

# --------------------------------------------------

TokenFile = "oauth_token.json"

if not File.exists?(TokenFile)
  puts "Not found #{ConsumerKeyFile}."
  puts "Please run 'get_access_token.rb' first, generate #{ConsumerKeyFile}"
end

tokens = JSON.parse(File.read(TokenFile))

Tumblr.configure do |config|
  config.consumer_key       = tokens["consumer_key"]
  config.consumer_secret    = tokens["consumer_secret"]
  config.oauth_token        = tokens["oauth_token"]
  config.oauth_token_secret = tokens["oauth_token_secret"]
end

client = Tumblr::Client.new
info = client.info
user_name = info["user"]["name"]
my_blog_name = info["user"]["blogs"].first["name"]

puts "YourBlogName is #{my_blog_name}"

my_blog_img_dir    = "MyBlogFiles"
other_blog_img_dir = "OtherFiles"


# Algorism
read_limit = 10000000 # Max read posts count

since_id = Dir.glob("{#{my_blog_img_dir},#{other_blog_img_dir}}/*").map{|f| f.match(/\d+/).to_s.to_i}.max || 0
puts "Since #{since_id}."

least_posts_count = read_limit

while least_posts_count > 0
  puts "Least #{least_posts_count}. "
  limit = [least_posts_count, 20].min

  # save_dashboard(client, limit, since_id, my_blog_name)
  since_id = save_dashboard(client, limit, since_id, my_blog_name)

  least_posts_count -= limit
end

exit

# valid_opts = [:limit, :offset, :type, :since_id, :reblog_info, :notes_info]

# "type":"photo"
# "date":"2016-10-23 01:43:47 GMT",
# "timestamp":1477187027,
# "liked":false,
