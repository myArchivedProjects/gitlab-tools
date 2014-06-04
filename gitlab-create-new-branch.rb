#!/usr/bin/env ruby
#
#
require 'gitlab'
require 'git-up'

if ENV['GITLAB_PRIVATE_TOKEN'].nil?
  puts 'Error: GITLAB_PRIVATE_TOKEN environment variable is not set'
  exit 1
else
  private_token = ENV['GITLAB_PRIVATE_TOKEN']
end

new_branch = ARGV[0]
gitlab_endpoint = 'http://gitlab.skyscape.preview-dvla.co.uk/gitlab/'

Gitlab.configure do |config|
  config.endpoint = "#{gitlab_endpoint}/api/v3"
  config.private_token = private_token
  config.user_agent     = 'Custom User Agent'
end

projects = Gitlab.projects(:per_page => 1000 )

def git_clone(basedir, origin)
  puts
  puts "processing: #{ origin }"
  pwd = Dir.pwd
  Dir.mkdir(basedir)
  Dir.chdir(basedir)
  %x( git clone "#{ origin }" )
  Dir.chdir(pwd)
end


def git_pull(basedir, repository)
  puts
  puts "doing a git-up pull on: #{ basedir }/#{ repository }"
  pwd = Dir.pwd
  Dir.chdir( "#{ basedir }/#{ repository }")
  %x( git-up )
  Dir.chdir(pwd)
end

def git_branch(basedir, repository, new_branch)
  puts
  puts "creating a new branch #{ new_branch } on: #{ basedir }/#{ repository }"
  pwd = Dir.pwd
  Dir.chdir( "#{ basedir }/#{ repository }")
  %x( git branch #{new_branch} )
  %x( git checkout #{new_branch} )
  %x( git-up )
  %x( git push origin #{new_branch} )
  Dir.chdir(pwd)
end


projects.each do |project|
  origin = project.to_hash["ssh_url_to_repo"].sub('accesspoint','gitlab.skyscape')
  basedir = project.to_hash["path_with_namespace"].split('/')[0]
  repository = project.to_hash["path_with_namespace"].split('/')[1]

  Dir.exist?(basedir) ? git_pull(basedir, repository) : git_clone(basedir, origin)
  git_branch(basedir, repository, new_branch)
end

