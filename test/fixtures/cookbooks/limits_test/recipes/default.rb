include_recipe "#{cookbook_name}::setup"

# limits_file has no converge_if_changed of its own, so the file resource
# declared inside it is what marks it updated. That is why its write is
# not silenced the way a limit's is, and these record the consequence of
# that decision rather than trusting it. Each of its three actions is
# covered, since each reaches the file resource differently, and a fourth
# recorder covers the action that correctly does nothing.
#
# Nothing else in this suite would notice if that stopped being true. A
# limits_file that quietly reported itself up to date would still write
# the right file, every content assertion here would still pass, and every
# notifies and subscribes a user had hung off one would silently stop
# firing.
#
# The same question about the limit resource is settled in spec/resources
# instead, where ChefSpec puts converge_if_changed to every case for the
# price of a few milliseconds. ChefSpec cannot answer it for limits_file at
# any price. It replaces Chef::Provider#compile_and_converge_action with a
# bare instance_eval, so no child run context is built and the step that
# marks a resource updated because a resource it declared was updated never
# runs. A limits_file under ChefSpec always reports itself up to date.
#
# Declared with action :nothing and notified immediately, so they run only
# when the resource they are attached to actually converged. Test Kitchen
# converges twice and fails on a second converge that changes anything, so
# a notification that fired unconditionally would fail the run.
%w(
  limits_file_create
  limits_file_purge
  limits_file_delete
  limits_file_unchanged
).each do |kind|
  ruby_block "record the #{kind} notification" do
    block { ::File.write("/tmp/notified_#{kind}", "#{kind}\n") }
    action :nothing
  end
end

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
  notifies :run, 'ruby_block[record the limits_file_create notification]', :immediately
end

# A limit that is already what it should be. The seed puts 'kitchen soft
# core 0' in this file and nothing changes it, so converge_if_changed has
# every property to compare and finds none of them different.
#
# Whether it notifies is settled in spec/resources. What it is here for is
# the second converge: a limit that converged when it had nothing to do
# would rewrite this file every run, and Test Kitchen fails a run whose
# second converge changes anything.
limit 'limit that is already correct' do
  path '/etc/security/limits.d/100_unpurged.conf'
  domain 'kitchen'
  type 'soft'
  item 'core'
  value 0
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

# Purge a file that does not exist. Nothing seeds it and no other resource
# names it, so the action finds no file and returns before it reads or
# declares anything. Two things worth asserting: it does not notify, and
# it does not create the file it was pointed at, because purge is not
# allowed to create anything.
limits_file '/etc/security/limits.d/600_absent.conf' do
  action :purge
  notifies :run, 'ruby_block[record the limits_file_unchanged notification]', :immediately
end

# Delete a limits file the setup recipe seeded, so the delete action has
# something to remove.
limits_file '/etc/security/limits.d/300_deleted.conf' do
  action :delete
  notifies :run, 'ruby_block[record the limits_file_delete notification]', :immediately
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

# nonewprivs is a boolean rather than a size or a count, and it is one of
# the items this cookbook accepts that not every pam_limits understands.
# Converging it proves the resource writes the item, which is all this
# cookbook is responsible for; whether the module honors it is a question
# about the pam on the node.
limit 'add a boolean item' do
  path '/etc/security/limits.d/400_created.conf'
  domain 'kitchen'
  type 'hard'
  item 'nonewprivs'
  value 1
end

# Purge a file without creating it. Every other limits_file here either
# creates or deletes, so without this the purge action is never asked to
# manage a file's ownership and mode on its own. The seed is laid down
# with the wrong owner and mode on purpose.
limits_file '/etc/security/limits.d/500_purged.conf' do
  mode '0640'
  action :purge
  notifies :run, 'ruby_block[record the limits_file_purge notification]', :immediately
end
