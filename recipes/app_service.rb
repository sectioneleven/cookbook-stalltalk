#
# Cookbook Name:: stalltalk
# Recipe:: app_service
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

include_recipe "stalltalk::app"

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
