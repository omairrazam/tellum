require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'rvm/capistrano'
set :stages, ["staging", "production", "staging2"]
set :default_stage, "staging"
