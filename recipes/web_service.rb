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

template "/etc/nginx/sites-available/#{node["stalltalk"]["project_name"]}" do
  source "nginx-site.erb"
  variables({
    upstream_name: node["stalltalk"]["project_name"],
    uwsgi_socket: node["stalltalk"]["uwsgi"]["socket"],
    uwsgi_socket_type: node["stalltalk"]["uwsgi"]["socket_type"],
    server_names: node["stalltalk"]["domain_names"],
    access_log_file: "#{node["stalltalk"]["project_path"]}/access.log",
    error_log_file: "#{node["stalltalk"]["project_path"]}/error.log",
    static_media_root: "#{node["stalltalk"]["project_path"]}/stalltalk/public",
    })
  notifies :reload, "service[nginx]"
end

nginx_site node["stalltalk"]["project_name"]
