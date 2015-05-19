set :db_local_clean, true
set :deploy_to, '/home/ubuntu/apps/tellum'
set :keep_releases, 5
set :rvm_ruby_string, '1.9.3-p484@tellum'
set :rvm_type, :user
server "54.191.253.112", :web, :app, :db, :primary => true
set :application, 'tellum'
set :scm        , :git
set :repository , 'https://ali_hassan_mirza:dazzlermirza123@bitbucket.org/ali_hassan_mirza/tellum.git'
set :branch, "master"
set :user       , 'ubuntu'
set :use_sudo   , false
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:auth_methods] = ["publickey"]
ssh_options[:keys] = ["/home/ali/.ssh/tellum_production.pem"]

namespace :paths do
  desc "Link paths of required files"
  task :link_paths do
    run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -sf #{shared_path}/uploads #{release_path}/public/uploads"
  end
end
namespace :unicorn_server do
  desc "Unicorn Server"
  task :restart do
    run "/etc/init.d/unicorn stop"
    run "/etc/init.d/unicorn start"
  end
end

after 'deploy:update_code', "paths:link_paths"
after 'deploy:update_code', "unicorn_server:restart"
#run "rake assets:precompile RAILS_ENV=production"
