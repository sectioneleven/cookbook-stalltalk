#
# Cookbook Name:: stalltalk
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
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
  content Chef::EncryptedDataBagItem.load("ssh_keys", "github")["private_key"]
end

file "/home/#{ node["stalltalk"]["user"] }/.ssh/github-id_rsa.pub" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0600
  content Chef::EncryptedDataBagItem.load("ssh_keys", "github")["public_key"]
end

ssh_util_config "github.com" do
  options({
    "IdentityFile" => "/home/#{ node["stalltalk"]["user"] }/.ssh/github-id_rsa",
    "StrictHostKeyChecking" => "no",
  })
  user node["stalltalk"]["user"]
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

%w[libpq-dev].each do |pkg|
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
