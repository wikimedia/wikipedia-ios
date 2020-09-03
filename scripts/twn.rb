#!/usr/bin/env ruby
# opens a PR when the twn branch changes. used by jenkins.

pr_branch = 'twn'
base_branch = 'develop'
time_string = Time.now.strftime("%m/%d/%Y")
title = "TWN sync on #{time_string}"

current_hash = `git ls-remote --heads origin | grep refs/heads/#{pr_branch}`.split.first

if !current_hash || current_hash == ''
  puts "no current hash"
  puts `git checkout #{base_branch}`
  puts `git checkout -b #{pr_branch}`
  puts `git push -u origin twn`
  current_hash = `git ls-remote --heads origin | grep refs/heads/#{pr_branch}`.split.first
  `echo "#{current_hash}" > #{hash_file}`
  exit 0
end

current_hash = current_hash.strip

hash_file = "~/PR_#{pr_branch.upcase}_CURRENT_HASH"

previous_hash = `cat #{hash_file}`

if previous_hash
  previous_hash = previous_hash.strip
end

if previous_hash == current_hash
  puts "no changes"
  exit 0
end

puts "#{pr_branch} went from #{previous_hash} to #{current_hash}, opening pr"

path = `pwd`.strip
puts `"#{path}/scripts/localization" "#{path}"`
puts `git add -A`
puts `git commit -a -m "Import localizations from TWN on #{time_string}"`
puts `git push -u origin twn`
puts `scripts/pr.rb #{pr_branch} #{base_branch} "#{title}"`

if $?.to_i == 0
  `echo "#{current_hash}" > #{hash_file}`
else 
  exit 1
end