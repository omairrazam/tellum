require 'bundler/capistrano'
require 'rvm/capistrano'
set :db_local_clean, true
set :deploy_to, '/home/deploy/projects/test/tellum'
set :keep_releases, 5
set :rvm_ruby_string, '1.9.3-p545@tellum'
set :rvm_type, :system
server "192.241.214.145", :web, :app, :db, :primary => true
set :application, 'tellum'
set :scm        , :git
set :repository , 'https://ali_hassan_mirza:dazzlermirza123@bitbucket.org/ali_hassan_mirza/tellum.git'
set :branch, "test"
set :user       , 'deploy'
set :default_shell, "/bin/bash -l"
set :use_sudo   , false

namespace :paths do
  desc "Link paths of required files"
  task :link_paths do
    run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -sf #{shared_path}/uploads #{release_path}/public/uploads"
  end
end
after 'deploy:update_code', "paths:link_paths"