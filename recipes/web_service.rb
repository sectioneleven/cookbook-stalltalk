#
# Cookbook Name:: stalltalk
# Recipe:: web_service
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

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
