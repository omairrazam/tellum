# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

role :app, %w{ubuntu@54.191.253.112}
role :web, %w{ubuntu@54.191.253.112}
role :db,  %w{ubuntu@54.191.253.112}
set :repo_url, 'git@bitbucket.org:tellumapp/tellum_server.git'
set :deploy_to, '/home/ubuntu/apps/tellum'
set :branch, :production
set :application, 'tellum'
set :rvm_ruby_version, '1.9.3-p484@tellum'



# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server 'ubuntu@54.191.253.112', user: 'ubuntu', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
server '54.191.253.112',
       user: 'ubuntu',
       roles: %w{web app},
       ssh_options: {
           user: 'root', # overrides user setting above
           keys: %w(/Users/AHMirza/.ssh/id_rsa),
           forward_agent: false,
           auth_methods: %w(publickey password)
           # password: 'please use keys'
       }
# setting per server overrides global ssh_options
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

# after 'deploy:update_code', "paths:link_paths"
# after 'deploy:update_code', "unicorn_server:restart"




# set :db_local_clean, true
# set :keep_releases, 5
# set :rvm_ruby_string, '1.9.3-p484@tellum'
# set :rvm_type, :user
# server "54.191.253.112", :web, :app, :db, :primary => true
# set :application, 'tellum'
# set :scm        , :git
# set :branch, "master"
# set :user       , 'ubuntu'
# set :use_sudo   , false
# default_run_options[:pty] = true
# ssh_options[:forward_agent] = true
# ssh_options[:auth_methods] = ["publickey"]
# ssh_options[:keys] = ["/home/ali/.ssh/tellum_production.pem"]

#run "rake assets:precompile RAILS_ENV=production"