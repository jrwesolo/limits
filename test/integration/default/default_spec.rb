describe file('/etc/security/limits.conf') do
  it { should exist }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0644' }
end

describe limits_conf('/etc/security/limits.conf') do
  its('*') { should eq [%w(hard rss 20000)] }
  its('@faculty') { should eq nil }
  its('@student') { should eq [%w(hard nproc 20)] }
  its('apple') { should eq nil }
  its('ftp') { should eq nil }
end

describe file('/etc/security/limits.d/100_kitchen.conf') do
  it { should exist }
  its('mode') { should cmp '0640' }
end

describe limits_conf('/etc/security/limits.d/100_kitchen.conf') do
  its('kitchen') { should include %w(soft core 0) }
  its('kitchen') { should include %w(soft cpu 66) }
end

describe file('/etc/security/limits.d/200_kitchen.conf') do
  it { should exist }
end

describe limits_conf('/etc/security/limits.d/200_kitchen.conf') do
  its('kitchen') { should include %w(hard nofile 65536) }
end

describe file('/etc/security/limits.d/300_kitchen.conf') do
  it { should_not exist }
end
