require 'date'
require 'octokit'
require 'json'
require 'optparse'

access_token = ENV['GITHUB_TOKEN']
if access_token.nil? || access_token.empty?
  puts 'You have to provide an API toke via the environment variable `GITHUB_TOKEN`'
  exit 1
end

IGNORE_USERS = %w[codeclimate[bot] dependabot[bot]]

Options = Struct.new(:repositories, :since, :count_what)
options = Options.new(
  repositories: [],
  since: Date.today.strftime('%Y-%m-01'),
  count_what: :comments
)

OptionParser.new do |opts|
  opts.banner = 'Usage: GITHUB_TOKEN=ABC123 ./activity-count.rb [options]'

  opts.on(
    '-rREPOS',
    '--repositories=REPOS',
    'Comma-separated list of repositories to look at'
  ) do |repositories|
    options.repositories = repositories.split(',')
  end

  opts.on(
    '-s[SINCE]',
    '--since=[SINCE]',
    'Only comments after the given date, defaults to the beginning of the current month'
  ) do |since|
    options.since = Date.parse(since).strftime('%Y-%m-%d')
  end

  opts.on(
    '-c[WHAT]',
    '--count=[WHAT]',
    'Count either the »comments« or opened »pull_requests« per user, defaults to »comments«'
  ) do |what|
    options.count_what = what.to_sym
  end
end.parse!

CLIENT = Octokit::Client.new(access_token: access_token)

# @param [Options] options
# @return [void]
def count_comments(options)
  puts "Looking for PR comments since: #{options.since}"
  CLIENT.auto_paginate = true

  comment_count = {}
  options.repositories.each do |repository|
    puts "Getting PR comments for #{repository}"

    pr_comments = CLIENT.pull_requests_comments(repository, since: options.since)
    issue_comments = CLIENT.issues_comments(repository, since: options.since)

    (pr_comments + issue_comments).each do |comment|
      next if IGNORE_USERS.include?(comment.user.login)

      comment_count[comment.user.login] ||= 0
      comment_count[comment.user.login] += 1
    end
  end

  puts "PR comments per user since #{options.since}:"
  comment_count.to_a.each { |user, count| puts "#{user},#{count}" }
end

# @param [Options] options
# @return [void]
def count_pull_requests(options)
  puts "Looking for PRs opened since: #{options.since}"

  pr_count = {}
  options.repositories.each do |repository|
    puts "Getting PRs for #{repository}"

    # paginate through all PRs until we reach the desired date
    pull_requests = CLIENT.pull_requests(repository, state: :closed)
    while pull_requests.last.created_at.to_datetime > DateTime.parse(options.since)
      pull_requests.concat CLIENT.get(CLIENT.last_response.rels[:next].href)
    end

    pull_requests.each do |pull_request|
      next if IGNORE_USERS.include?(pull_request.user.login)
      next if pull_request.created_at.to_datetime < DateTime.parse(options.since)

      pr_count[pull_request.user.login] ||= 0
      pr_count[pull_request.user.login] += 1
    end
  end

  puts "PRs per user since #{options.since}:"
  pr_count.to_a.each { |user, count| puts "#{user},#{count}" }
end

case options.count_what
when :comments then count_comments(options)
when :pull_requests then count_pull_requests(options)
else
  puts 'Invalid value for --count, valid options are »comments« or »pull_requests«'
  exit 1
end
