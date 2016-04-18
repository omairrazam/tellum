# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

# role :app, %w{ubuntu@52.25.164.35}
# role :web, %w{ubuntu@52.25.164.35}
# role :db,  %w{ubuntu@52.25.164.35}

role :app, %w{ubuntu@54.213.18.15}
role :web, %w{ubuntu@54.213.18.15}
role :db,  %w{ubuntu@54.213.18.15}


set :repo_url, 'git@bitbucket.org:tellumapp/tellum_server.git'
set :deploy_to, '/home/ubuntu/projects/staging/tellum_server'
set :application, 'tellum_server'
set :rvm_ruby_version, 'ruby-1.9.3-p551@tellum_server'


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server 'ubuntu@54.213.18.15', user: 'ubuntu', roles: %w{web app}, my_property: :my_value


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
server '54.213.18.15',
       user: 'ubuntu',
       roles: %w{web app},
       ssh_options: {
           user: 'root', # overrides user setting above
           keys: %w(/home/vagrant/.ssh/.ssh/id_rsa),
           forward_agent: false,
           auth_methods: %w(publickey password)
           # password: 'please use keys'
       }
# setting per server overrides global ssh_options
namespace :paths do
  desc "Link paths of required files"
  task :link_paths do
    #run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -sf #{shared_path}/uploads #{release_path}/public/uploads"
  end
end