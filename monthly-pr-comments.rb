#
# USAGE:
# GITHUB_REPO="dsager/github-stats" GITHUB_TOKEN=ABC123 ./monthly-pr-comments.rb
#

require 'date'
require 'octokit'

ACCESS_TOKEN = ENV['GITHUB_TOKEN']
REPOSITORY = ENV['GITHUB_REPO']
SINCE = ENV['GITHUB_SINCE'] || Date.today.strftime('%Y-%m-01')
BLACKLISTED_USERS = %w(houndci houndci-bot devexbot)

if ACCESS_TOKEN.nil? || REPOSITORY.nil?
  raise ArgumentError,
        'You have to provide env vars `GITHUB_TOKEN` & `GITHUB_REPO`'
end

puts 'month,comments'

Octokit.auto_paginate = true
Octokit::Client
  .new(access_token: ACCESS_TOKEN)
  .pull_requests_comments(REPOSITORY, since: SINCE)
  .select do |comment|
    !BLACKLISTED_USERS.include?(comment.user.login) && comment.body.length > 10
  end
  .each_with_object({}) do |comment, hash|
    month = comment.created_at.to_date.strftime('%Y-%m')
    hash[month] = (hash[month] || 0) + 1
  end
  .sort
  .each { |month, count| puts "#{month},#{count}" }
