#!/usr/bin/env ruby

pr_branch = 'twn'
base_branch = 'develop'
title = 'localization'

current_hash = `git ls-remote --heads origin | grep refs/heads/#{pr_branch}`.split.first.strip

if !current_hash || current_hash == ''
  puts "no current hash"
  abort
end

hash_file = "~/PR_#{pr_branch.upcase}_CURRENT_HASH"

previous_hash = `cat #{hash_file}`.strip
`echo "#{current_hash}" > #{hash_file}`

if previous_hash == current_hash
  puts "no changes"
  abort
end

puts "#{pr_branch} went from #{previous_hash} to #{current_hash}, opening pr"
  
puts `curl -i -d '{"title":"#{title}","head":"#{pr_branch}","base":"#{base_branch}"}' -H "Authorization: token#{ENV['GITHUB_TWN_ACCESS_TOKEN']} " -H "Content-Type: application/json; charset=utf-8" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/wikimedia/wikipedia-ios/pulls`