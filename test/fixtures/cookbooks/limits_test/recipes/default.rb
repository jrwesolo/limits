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
limits_file '/etc/security/limits.d/100_unpurged.conf' do
  mode '0640'
  action :create
end

limit 'add limit to unpurged limits file' do
  path '/etc/security/limits.d/100_unpurged.conf'
  domain 'kitchen'
  type 'soft'
  item 'cpu'
  value '66'
  comment 'Comment for new limit'
end

limit 'add limit to unmanaged and non-existent limits file' do
  path '/etc/security/limits.d/200_unmanaged.conf'
  domain 'kitchen'
  type 'hard'
  item 'nofile'
  value 65536
end

# Delete a limits file the setup recipe seeded, so the delete action has
# something to remove.
limits_file '/etc/security/limits.d/300_deleted.conf' do
  action :delete
end

# Manage a file that does not exist yet. Everything above starts from a
# file something else created, so without this the create action is never
# asked to make one from nothing.
limits_file '/etc/security/limits.d/400_created.conf' do
  mode '0600'
  action :create
end

limit 'add a limit with a word value' do
  path '/etc/security/limits.d/400_created.conf'
  domain 'kitchen'
  type 'hard'
  item 'nofile'
  value 'unlimited'
  comment 'Values are not all numbers'
end
