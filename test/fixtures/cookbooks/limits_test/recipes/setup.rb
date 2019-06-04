# These resource are only intended to do some initial
# configuration as a starting point for testing. The
# resources will be skipped once the files are managed
# by the limits cookbook custom resources.

files_for_setup = %w(
  /etc/security/limits.conf
  /etc/security/limits.d/100_kitchen.conf
)

files_for_setup.each do |path|
  cookbook_file path do
    source ::File.basename(path)
    owner 'nobody'
    group 'nobody'
    mode '0755'
    backup false
    action :create
    not_if { ::File.exist?(path) && ::File.foreach(path).grep(/managed by Chef/).any? }
  end
end
