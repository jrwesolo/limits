#
## Author:: Alexey Mochkin <alukardd@alukardd.org>
## Cookbook Name:: squid
## Recipe:: default
## Cookbook author:: Jordan Wesolowski <jrwesolo@gmail.com>
##
## Copyright 2016-2016
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing http_access and
## limitations under the License.
##
#

node['limits']['limits'].each do |name, limit|
  set_limit name do
    filename limit['filename'] unless limit['filename'].nil? || limit['filename'].empty?
    domain limit['domain'] unless limit['domain'].nil? || limit['domain'].empty?
    type limit['type']
    item limit['item']
    value limit['value']
    use_system true if limit['use_system']
  end
end

# vim: ts=2 sw=2 expandtab
