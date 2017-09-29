# config valid only for current version of Capistrano
lock '3.8.0'

set :rvm_ruby_version, '2.1.3'
set :rvm_type, :user
set :ssh_options, { forward_agent: true, user: 'deploy', password: 'PH_GEX_PASSWD4', paranoid: false}
#set :pty, true
set :default_shell, '/bin/bash -l'
set :rvm_type, :system
#
set :rsync_options, %w[
  --recursive --delete --delete-excluded
  --exclude .git*
  --exclude /test/***
]

set :deploy_to, "/var/www/apps/#{fetch(:application)}"

set :deploy_user, 'deploy'

role :app, %w{35.166.222.201}
role :web, %w{35.166.222.201}
role :db,  %w{35.166.222.201}


#
server '35.166.222.201', user: 'deploy', roles: %w{web}, primary: true

#
set :repo_url, 'ssh://git@gex1.devgex.net:5522/gex/docker-fiddle.git'
#set :repo_url, '.'

# set in :stage file
#set :application, 'appname'


# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5



# Add necessary files and directories which can be changed on server.
my_config_dirs = %W{config config/environments}
#my_config_files = %W{config/database.yml config/secrets.yml config/environments/#{fetch(:stage)}.rb }
my_app_dirs = %W{public/system public/uploads public/img app/views}


# do not change below
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
#set :linked_dirs, fetch(:linked_dirs) + my_app_dirs
#set :linked_files, fetch(:linked_files, []) + my_config_files

set :config_dirs,  my_config_dirs+my_app_dirs
#set :config_files, my_config_files

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/secrets.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
