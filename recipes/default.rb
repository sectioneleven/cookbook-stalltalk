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

python_virtualenv "/home/#{ node["stalltalk"]["user"] }/.virtualenvs/stalltalk" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

directory "/home/#{ node["stalltalk"]["user"] }/Projects" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

include_recipe "git"

git "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk" do
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

%w[libpq-dev postgis].each do |pkg|
  package pkg
end

bash "install requirements" do
  user node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  environment({"PIP_DOWNLOAD_CACHE" => "/home/#{ node["stalltalk"]["user"] }/.pip_download_cache"})
  code <<-EOH
    source /home/#{ node["stalltalk"]["user"] }/.virtualenvs/stalltalk/bin/activate
    pip install -r /home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/requirements.txt --log=/home/#{ node["stalltalk"]["user"]}/pip.log
  EOH
end

template "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/.env" do
  source "env.erb"
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  variables({
    db_host: node["stalltalk"]["db_host"],
    db_name: node["stalltalk"]["db_name"],
    db_user: node["stalltalk"]["db_user"],
    db_pass: node["stalltalk"]["db_pass"],
    email_use_tls: node["stalltalk"]["email_use_tls"],
    email_host: node["stalltalk"]["email_host"],
    email_host_user: node["stalltalk"]["email_host_user"],
    email_host_password: node["stalltalk"]["email_host_password"],
    email_port: node["stalltalk"]["email_port"],
    raven_dsn: node["stalltalk"]["raven_dsn"],
    google_analytics_tracking_id: node["stalltalk"]["google_analytics_tracking_id"],
    rfp_notification_email_to: node["stalltalk"]["rfp_notification_email_to"],
    property_notification_email_to: node["stalltalk"]["property_notification_email_to"],
  })
end

directory "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/deploy" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

template "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/deploy/production.ini" do
  source "production-uwsgi.ini.erb"
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  variables({
    user: node["stalltalk"]["user"],
    project_dir: "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk",
    virtualenv: "/home/#{ node["stalltalk"]["user"] }/.virtualenvs/stalltalk",
    wsgi_module: "stalltalk.wsgi:application",
    socket_file: node["stalltalk"]["uwsgi"]["socket_file"],
    uwsgi_logfile: "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/uwsgi.log",
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
    uwsgi_bin: "/home/#{ node["stalltalk"]["user"] }/.virtualenvs/stalltalk/bin/uwsgi",
    uwsgi_conf: "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/deploy/production.ini",
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
    access_log_file: "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/access.log",
    error_log_file: "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/error.log",
    static_media_root: "/home/#{ node["stalltalk"]["user"] }/Projects/stalltalk/stalltalk/public",
    })
end

nginx_site 'stalltalk'
