#
# Author:: Baptiste Courtois (<b.courtois@criteo.com>)
# Cookbook Name:: wsus-server
# Recipe:: install
#
# Copyright:: Copyright (c) 2014 Criteo.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# WSUS is a windows only feature
return unless platform?('windows')

setup_conf = node['wsus_server']['setup']

setup_options = ''
if setup_conf['sqlinstance_name']
  if node['platform_version'].to_f >= 6.2
    setup_options << " SQL_INSTANCE_NAME=\"#{setup_conf['sqlinstance_name']}\""
  else
    setup_options << " SQLINSTANCE_NAME=\"#{setup_conf['sqlinstance_name']}\""
  end
end

if setup_conf['content_dir']
  setup_options << " CONTENT_DIR=\"#{setup_conf['content_dir']}\""
end

windows_feature_powershell 'UpdateServices' do
  management_tools  true
end

guard_file = ::File.join(Chef::Config['file_cache_path'], 'wsus_postinstall')

execute 'WSUS PostInstall' do
  cwd            'C:\Program Files\Update Services\Tools'
  command        "WsusUtil.exe PostInstall #{setup_options}"
  not_if { ::File.exist?(guard_file) && ::File.read(guard_file) == setup_options }
end

file guard_file do
  path           guard_file
  content        setup_options
end

include_recipe 'wsus-server::configure'          unless setup_conf['frontend_setup']
