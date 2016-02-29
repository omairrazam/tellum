# config valid only for Capistrano 3.1
lock '3.2.1'
set :rvm_require_role, :app

# set :application, 'tellum_server'
# set :repo_url, 'git@bitbucket.org:tellumapp/tellum_server.git'
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
# set :deploy_to, '/home/ubuntu/projects/staging/tellum_server'
# set :rvm_ruby_version, 'ruby-1.9.3-p551@tellum_server'
set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}
# puma configuration
# set :puma_bind,       "unix:///tmp/branching_minds_puma.sock"
# set :puma_state,      "/tmp/branching_minds_puma.state"
# set :puma_pid,        "/tmp/branching_minds_puma.pid"
# set :puma_access_log, "#{release_path}/log/puma.error.log"
# set :puma_error_log,  "#{release_path}/log/puma.access.log"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end

end
