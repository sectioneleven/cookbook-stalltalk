#
# Cookbook Name:: stalltalk
# Recipe:: default
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

user_account node["stalltalk"]["user"] do
  ssh_keygen false
  ssh_keys node["stalltalk"]["authorized_keys"]
end

directory "/home/#{ node["stalltalk"]["user"] }/.ssh" do
  action :create
  user node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0700
end

file "/home/#{ node["stalltalk"]["user"] }/.ssh/github-id_rsa" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0600
  content Chef::EncryptedDataBagItem.load("ssh_keys", "github")[node.chef_environment]["private_key"]
end

file "/home/#{ node["stalltalk"]["user"] }/.ssh/github-id_rsa.pub" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0600
  content Chef::EncryptedDataBagItem.load("ssh_keys", "github")[node.chef_environment]["public_key"]
end

ssh_util_config "github.com" do
  options({
    "IdentityFile" => "/home/#{ node["stalltalk"]["user"] }/.ssh/github-id_rsa",
    "StrictHostKeyChecking" => "no",
  })
  user node["stalltalk"]["user"]
end

bash "chmod_config" do
  code <<-EOH
    chmod 600 /home/#{ node["stalltalk"]["user"] }/.ssh/config
    EOH
end


include_recipe "python"

directory "/home/#{ node["stalltalk"]["user"] }/.virtualenvs" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

python_virtualenv node["stalltalk"]["virtualenv_path"] do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

directory "/home/#{ node["stalltalk"]["user"] }/Projects" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

include_recipe "git"

git node["stalltalk"]["project_path"] do
  repository node["stalltalk"]["git"]["repository"]
  reference node["stalltalk"]["git"]["reference"]
  user node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  action :sync
end

directory "/home/#{ node["stalltalk"]["user"] }/.pip_download_cache" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

%w[libpq-dev postgis postgresql-client libjpeg-dev libpng-dev].each do |pkg|
  package pkg
end

bash "install requirements" do
  user node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  environment({"PIP_DOWNLOAD_CACHE" => "/home/#{ node["stalltalk"]["user"] }/.pip_download_cache"})
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    pip install -r #{node["stalltalk"]["project_path"]}/requirements.txt --log=/home/#{ node["stalltalk"]["user"]}/pip.log
  EOH
end

template "#{node["stalltalk"]["project_path"]}/.env" do
  source "env.erb"
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  variables({
    db_host: node["stalltalk"]["db_host"],
    db_name: node["stalltalk"]["db_name"],
    db_user: node["stalltalk"]["db_user"],
    db_pass: node["stalltalk"]["db_pass"].empty? ? Chef::EncryptedDataBagItem.load("stalltalk", "passwords")[node.chef_environment]["database"] : node["stalltalk"]["db_pass"],
    email_use_tls: node["stalltalk"]["email_use_tls"],
    email_host: node["stalltalk"]["email_host"],
    email_host_user: node["stalltalk"]["email_host_user"],
    email_host_password: node["stalltalk"]["email_host_password"].empty? ? Chef::EncryptedDataBagItem.load("stalltalk", "passwords")[node.chef_environment]["email"] : node["stalltalk"]["email_host_password"],
    email_port: node["stalltalk"]["email_port"],
    raven_dsn: node["stalltalk"]["raven_dsn"],
    google_analytics_tracking_id: node["stalltalk"]["google_analytics_tracking_id"],
    rfp_notification_email_to: node["stalltalk"]["rfp_notification_email_to"],
    property_notification_email_to: node["stalltalk"]["property_notification_email_to"],
  })
end


include_recipe "nodejs"

bash "install node packages" do
  user node["stalltalk"]["user"]
  environment({"HOME" => "/home/#{ node["stalltalk"]["user"] }"})
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    npm install
    EOH
end

bash "install bower packages" do
  user node["stalltalk"]["user"]
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    ./manage.py bower_install -- --config.interactive=false
    EOH
end


bash "collectstatic" do
  user node["stalltalk"]["user"]
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    ./manage.py collectstatic --noinput
    EOH
end


directory "#{node["stalltalk"]["project_path"]}/deploy" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

template "#{node["stalltalk"]["project_path"]}/deploy/production.ini" do
  source "production-uwsgi.ini.erb"
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  variables({
    user: node["stalltalk"]["user"],
    project_dir: node["stalltalk"]["project_path"],
    virtualenv: node["stalltalk"]["virtualenv_path"],
    wsgi_module: "stalltalk.wsgi:application",
    socket_file: node["stalltalk"]["uwsgi"]["socket_file"],
    uwsgi_logfile: "#{node["stalltalk"]["project_path"]}/uwsgi.log",
    num_process: 2,
    })
end

template "/etc/init/stalltalk.conf" do
  source "stalltalk-upstart.conf.erb"
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  variables({
    user: node["stalltalk"]["user"],
    group: node["stalltalk"]["group"],
    uwsgi_bin: "#{node["stalltalk"]["virtualenv_path"]}/bin/uwsgi",
    uwsgi_conf: "#{node["stalltalk"]["project_path"]}/deploy/production.ini",
    })
end

service "stalltalk" do
  provider Chef::Provider::Service::Upstart
  supports restart: true, status: true
  action [:enable, :start]
end

include_recipe "nginx"

nginx_site 'default' do
  enable false
end

template "/etc/nginx/sites-available/stalltalk" do
  source "nginx-site.erb"
  variables({
    uwsgi_socket_file: node["stalltalk"]["uwsgi"]["socket_file"],
    server_names: node["stalltalk"]["domain_names"],
    access_log_file: "#{node["stalltalk"]["project_path"]}/access.log",
    error_log_file: "#{node["stalltalk"]["project_path"]}/error.log",
    static_media_root: "#{node["stalltalk"]["project_path"]}/stalltalk/public",
    })
end

nginx_site 'stalltalk'
