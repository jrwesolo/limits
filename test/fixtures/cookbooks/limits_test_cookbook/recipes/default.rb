%w(alice bob).each do |u|
  # Creating the home directory manually because it was not getting created
  # automatically on Ubuntu. This was causing extra output in the rspec commands
  # and failing tests.
  user u do
    home "/home/#{u}"
  end
  directory "/home/#{u}" do
    owner u
  end
end

# This is needed for rspec tests. On Ubuntu, it seemed that limits weren't
# enabled in the correct /etc/pam.d files. Adding this manually. In the future,
# maybe we add this into the cookbook or lwrp.
if platform_family?('debian')
  pam_check = '[ -f common-session ] && ' \
              '! grep -qE "^session\s+required\s+pam_limits.so" common-session'
  execute 'enabling pam_limits' do
    cwd '/etc/pam.d'
    command 'echo "session required pam_limits.so" >> common-session'
    only_if pam_check, cwd: '/etc/pam.d'
  end
end

%w(basic empty invalid mixed sanitized system).each do |r|
  include_recipe "#{cookbook_name}::#{r}"
end
