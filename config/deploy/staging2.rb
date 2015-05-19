require 'bundler/capistrano'
require 'rvm/capistrano'
set :db_local_clean, true
set :deploy_to, '/home/ubuntu/projects/staging/tellum_server'
set :keep_releases, 5
set :rvm_ruby_string, 'ruby-1.9.3-p551@tellum'
set :rvm_type, :user
server "52.25.164.35", :web, :app, :db, :primary => true
set :application, 'tellum'
set :scm        , :git
set :repository , 'git@bitbucket.org:tellumapp/tellum_server.git'
set :branch, "test"
set :user       , 'ubuntu'
set :default_shell, "/bin/bash -l"
set :use_sudo   , false
before 'deploy:setup', 'rvm:install_rvm'
namespace :paths do
  desc "Link paths of required files"
  task :link_paths do
    run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -sf #{shared_path}/uploads #{release_path}/public/uploads"
  end
end
after 'deploy:update_code', "paths:link_paths"