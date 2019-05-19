require 'mongrel_cluster/recipes'

set :application, "CRdata"
set :repository, "git@github.com:sparktech/CRdata.git"
set :scm, :git
#set :deploy_via, :remote_cache
set :branch, "master"
set :use_sudo, false
set :user, 'rails_deploy'
set :synchronous_connect, true
set :deploy_to, "/var/rails/crdata"
set :mongrel_conf, "#{deploy_to}/current/config/mongrel_cluster.yml"

ssh_options[:port] = 2222
ssh_options[:forward_agent] = true 

if ENV['DEPLOY'] == 'PRODUCTION'
 set :deploy_as, 'production'
 
 role :app, "ec2-75-101-145-144.compute-1.amazonaws.com"
 role :web, "ec2-75-101-145-144.compute-1.amazonaws.com"
 role :db,  "ec2-75-101-145-144.compute-1.amazonaws.com", :primary => true
 
elsif ENV['DEPLOY'] == 'STAGING'
 set :deploy_as, 'staging'
 role :app, "ec2-174-129-36-100.compute-1.amazonaws.com"
 role :web, "ec2-174-129-36-100.compute-1.amazonaws.com"
 role :db,  "ec2-174-129-36-100.compute-1.amazonaws.com", :primary => true
else
 puts 'You must set the DEPLOY env var to either PRODUCTION or STAGING'
 raise "Can't continue!"
end


namespace :crdata do
  task :fix_config_files, :roles => [:app, :db] do
    run "cp #{release_path}/config/#{deploy_as}_database.yml #{release_path}/config/database.yml"
    run "cp #{release_path}/config/#{deploy_as}_mongrel_cluster.yml #{release_path}/config/mongrel_cluster.yml"
    run "cp #{release_path}/config/#{deploy_as}_settings.yml #{release_path}/config/settings.yml"
  end
end

after "deploy:update_code", "crdata:fix_config_files"
