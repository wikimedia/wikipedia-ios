#!/usr/bin/env ruby
# opens a PR against the repo. used by jenkins to open localization PRs

pr_branch = ARGV[0]
base_branch = ARGV[1]
title = ARGV[2]

if !title || !pr_branch || !base_branch
  puts "missing arguments"
  exit 1
end

result = `curl -i -d '{"title":"#{title}","head":"#{pr_branch}","base":"#{base_branch}"}' -H "Authorization: token #{ENV['GITHUB_TWN_ACCESS_TOKEN']}" -H "Content-Type: application/json; charset=utf-8" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/wikimedia/wikipedia-ios/pulls`
puts result

if result.include?('HTTP/1.1 201 Created') || result.include?('A pull request already exists') || result.include?('No commits between')
  exit 0
else
  exit 1
end