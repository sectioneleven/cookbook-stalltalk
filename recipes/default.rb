#
# Cookbook Name:: stalltalk
# Recipe:: default
#
# Copyright (C) 2014 Lemuel Formacil
#
# All rights reserved - Do Not Redistribute
#

include_recipe "stalltalk::user_account"
include_recipe "stalltalk::app"
include_recipe "stalltalk::app_service"
include_recipe "stalltalk::web_service"
