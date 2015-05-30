#
# Cookbook Name:: stalltalk
# Recipe:: app
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

user_home = "/home/#{node["stalltalk"]["user"]}"

include_recipe "stalltalk::user_account"
include_recipe "python"

directory "#{user_home}/.virtualenvs" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

python_virtualenv node["stalltalk"]["virtualenv_path"] do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
end

directory "#{user_home}/Projects" do
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

%w[libpq-dev postgis postgresql-client libjpeg-dev libpng-dev].each do |pkg|
  package pkg
end

bash "install requirements" do
  user node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  environment({"HOME" => user_home})
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    pip install -r #{node["stalltalk"]["project_path"]}/requirements.txt --log=#{user_home}/pip.log
  EOH
end

template "#{node["stalltalk"]["project_path"]}/.env" do
  source "env.erb"
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  variables({
    site_id: node["stalltalk"]["site_id"],
    allowed_hosts: node["stalltalk"]["allowed_hosts"],
    db_host: node["stalltalk"]["db_host"],
    db_port: node["stalltalk"]["db_port"],
    db_name: node["stalltalk"]["db_name"],
    db_user: node["stalltalk"]["db_user"],
    db_pass: begin Chef::EncryptedDataBagItem.load("stalltalk", "passwords")[node.chef_environment]["database"] rescue node["stalltalk"]["db_pass"] end,
    email_use_tls: node["stalltalk"]["email_use_tls"],
    email_host: node["stalltalk"]["email_host"],
    email_host_user: node["stalltalk"]["email_host_user"],
    email_host_password: begin Chef::EncryptedDataBagItem.load("stalltalk", "passwords")[node.chef_environment]["email"] rescue node["stalltalk"]["email_host_password"] end,
    email_port: node["stalltalk"]["email_port"],
    raven_dsn: node["stalltalk"]["raven_dsn"],
    google_analytics_tracking_id: node["stalltalk"]["google_analytics_tracking_id"],
    rfp_notification_email_to: node["stalltalk"]["rfp_notification_email_to"],
    property_notification_email_to: node["stalltalk"]["property_notification_email_to"],
    celery_redis_host: node["stalltalk"]["celery_redis_host"],
    celery_redis_port: node["stalltalk"]["celery_redis_port"],
    default_file_storage: node["stalltalk"]["default_file_storage"],
    staticfiles_storage: node["stalltalk"]["staticfiles_storage"],
    aws_access_key_id: node["stalltalk"]["aws_access_key_id"],
    aws_secret_access_key: node["stalltalk"]["aws_secret_access_key"],
    aws_storage_bucket_name: node["stalltalk"]["aws_storage_bucket_name"],
  })
end

bash "syncdb" do
  user node["stalltalk"]["user"]
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    ./manage.py syncdb --noinput
    EOH
end

bash "create superuser" do
  user node["stalltalk"]["user"]
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    echo '
    from django.contrib.auth.models import User
    User.objects.create_superuser("#{node["stalltalk"]["admin_user"]}", "#{node["stalltalk"]["admin_email"]}", "#{node["stalltalk"]["admin_pass"]}")' | ./manage.py shell
    EOH
  not_if "echo 'from django.contrib.auth.models import User; len(User.objects.filter(pk=2)) > 0' | ./manage.py shell --plain | grep True"
end

bash "migrate" do
  user node["stalltalk"]["user"]
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    source #{node["stalltalk"]["virtualenv_path"]}/bin/activate
    ./manage.py migrate
    EOH
end


include_recipe "nodejs"

bash "install node packages" do
  user node["stalltalk"]["user"]
  environment({"HOME" => user_home})
  cwd node["stalltalk"]["project_path"]
  code <<-EOH
    npm install
    EOH
end

bash "install bower packages" do
  user node["stalltalk"]["user"]
  environment({"HOME" => user_home})
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
