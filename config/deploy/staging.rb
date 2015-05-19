require 'bundler/capistrano'
require 'rvm/capistrano'
set :db_local_clean, true
set :deploy_to, '/root/projects/stagging/tellum'
set :keep_releases, 5
set :rvm_ruby_string, '1.9.3-p429@tellum'
set :rvm_type, :system
server "198.199.65.232", :web, :app, :db, :primary => true
set :application, 'tellum'
set :scm        , :git
set :repository , 'https://ali_hassan_mirza:dazzlermirza123@bitbucket.org/ali_hassan_mirza/tellum.git'
set :branch, "stagging"
set :user       , 'root'
set :use_sudo   , false

namespace :paths do
  desc "Link paths of required files"
  task :link_paths do
    run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -sf #{shared_path}/uploads #{release_path}/public/uploads"
  end
end
after 'deploy:update_code', "paths:link_paths"