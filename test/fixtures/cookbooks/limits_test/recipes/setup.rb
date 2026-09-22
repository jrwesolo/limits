# These resources are only intended to do some initial
# configuration as a starting point for testing. They are
# seeded once per container and never run again, which leaves
# the limits cookbook custom resources to own the files from
# then on.
#
# 300_deleted.conf is seeded only so that the delete action in
# the default recipe has something to delete. Without it the
# integration test asserts that a file nobody ever created is
# absent, which passes whether or not the action works.

files_for_setup = %w(
  /etc/security/limits.conf
  /etc/security/limits.d/100_unpurged.conf
  /etc/security/limits.d/300_deleted.conf
)

files_for_setup.each do |path|
  cookbook_file path do
    source ::File.basename(path)
    owner node['setup']['owner']
    group node['setup']['group']
    mode '0755'
    backup false
    action :nothing
  end
end

# The marker is what makes the seeding happen once rather than once per
# converge. Test Kitchen converges twice and fails the run if the second
# converge changes anything, so a seed that fired every time would either
# fight the cookbook for the files it manages or restore the file the
# default recipe deletes.
#
# Asking each file whether it had been managed yet would not do. That
# question becomes true for the two files the cookbook rewrites, because it
# leaves a header in them, and never becomes true for 300_deleted.conf,
# which is deleted rather than managed.
#
# The notifications are immediate on purpose. A delayed notification runs
# at the end of the run, after limits_file and limit have converged, which
# would seed the files again on top of what the cookbook just wrote.
file '/tmp/limits_test_seeded' do
  action :create

  files_for_setup.each do |path|
    notifies :create, "cookbook_file[#{path}]", :immediately
  end
end
