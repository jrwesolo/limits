# ChefSpec is deliberately not used here. The custom resources read and
# write the live filesystem at converge time (Limits::File.new reads the
# real path), so stepping into them under ChefSpec would touch the host's
# own /etc/security/limits.conf. Resource behaviour is covered by the
# Test Kitchen integration suite instead; these specs exercise the
# library classes directly.

Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
  config.order = 'random'
end
