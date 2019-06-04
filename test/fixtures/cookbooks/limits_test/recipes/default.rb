include_recipe "#{cookbook_name}::setup"

# Manage an existing limits file and purge limits not maintained by Chef.
limits_file '/etc/security/limits.conf' do
  action [:create, :purge]
end

limit 'change value and keep comment' do
  domain '*'
  type 'hard'
  item 'rss'
  value '20000'
  action :create
end

limit 'set comment on existing limit' do
  domain '@student'
  type 'hard'
  item 'nproc'
  value 20
  comment 'This is a new comment'
  action :create
end

limit 'delete an existing limit' do
  domain '@faculty'
  type 'soft'
  item 'nproc'
  action :delete
end

limit 'delete non-existent limit' do
  domain 'apple'
  type 'soft'
  item 'cpu'
  action :delete
end

# Manage an existing limits file and keep any existing limits.
limits_file '/etc/security/limits.d/100_kitchen.conf' do
  mode '0640'
  action :create
end

limit 'add limit to unpurged limits file' do
  path '/etc/security/limits.d/100_kitchen.conf'
  domain 'kitchen'
  type 'soft'
  item 'cpu'
  value '66'
  comment 'Comment for new limit'
end

limit 'add limit to unmanaged and non-existent limits file' do
  path '/etc/security/limits.d/200_kitchen.conf'
  domain 'kitchen'
  type 'hard'
  item 'nofile'
  value 65536
end

# Delete non-existent limits file.
limits_file '/etc/security/limits.d/300_kitchen.conf' do
  action :delete
end
