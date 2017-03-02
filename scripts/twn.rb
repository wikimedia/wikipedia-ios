#!/usr/bin/env ruby

pr_branch = 'twn'
base_branch = 'develop'
title = "TWN sync on #{Time.now.strftime("%m/%d/%Y")}"

current_hash = `git ls-remote --heads origin | grep refs/heads/#{pr_branch}`.split.first

if !current_hash || current_hash == ''
  puts "no current hash"
  puts `git checkout develop`
  puts `git checkout -b twn`
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

`scritps/pr.rb #{pr_branch} #{develop} "#{title}"`

if $?.to_i == 0
  `echo "#{current_hash}" > #{hash_file}`
else 
  exit 1
end