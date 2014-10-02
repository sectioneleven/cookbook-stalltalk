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
