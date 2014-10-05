#
# Cookbook Name:: stalltalk
# Recipe:: worker
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

template "/etc/init/stalltalk-worker.conf" do
  source "stalltalk-worker-upstart.conf.erb"
  variables({
    :uid => node["stalltalk"]["user"],
    :gid => node["stalltalk"]["group"],
    :project_path => node["stalltalk"]["project_path"],
    :project_env_file => "#{node["stalltalk"]["project_path"]}/.env",
    :project_env_path => node["stalltalk"]["virtualenv_path"],
    :log_level => "debug",
    })
  notifies :restart, "service[stalltalk-worker]"
end

service "stalltalk-worker" do
  provider Chef::Provider::Service::Upstart
  supports restart: true, status: true
  action [:nothing]
end
