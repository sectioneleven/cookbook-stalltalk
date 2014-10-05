#
# Cookbook Name:: stalltalk
# Recipe:: user_account
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

user_home = "/home/#{node["stalltalk"]["user"]}"

user_account node["stalltalk"]["user"] do
  ssh_keygen false
  ssh_keys node["stalltalk"]["authorized_keys"]
end

directory "#{user_home}/.ssh" do
  action :create
  user node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0700
end

file "#{user_home}/.ssh/github-id_rsa" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0600
  content Chef::EncryptedDataBagItem.load("ssh_keys", "github")[node.chef_environment]["private_key"]
end

file "#{user_home}/.ssh/github-id_rsa.pub" do
  owner node["stalltalk"]["user"]
  group node["stalltalk"]["group"]
  mode 0600
  content Chef::EncryptedDataBagItem.load("ssh_keys", "github")[node.chef_environment]["public_key"]
end

ssh_util_config "github.com" do
  options({
    "IdentityFile" => "#{user_home}/.ssh/github-id_rsa",
    "StrictHostKeyChecking" => "no",
  })
  user node["stalltalk"]["user"]
end

bash "chmod_config" do
  code <<-EOH
    chmod 600 #{user_home}/.ssh/config
    EOH
end
