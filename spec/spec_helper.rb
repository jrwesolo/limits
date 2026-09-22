# ChefSpec is deliberately not used here, on cost rather than on safety.
# Stepping into a resource is opt-in, so a plain ChefSpec run never
# converges these resources at all: it would assert that a resource was
# declared with certain properties, which for a cookbook that ships no
# recipes tests the fixture cookbook rather than this one. Stepping in
# would converge them for real, and they read and write whichever path
# they are handed, so each such spec would have to point at a tmpdir to
# stay away from the host's own /etc/security/limits.conf.
#
# Neither is worth the price while the logic lives in libraries/ and
# these specs run in milliseconds. Resource behavior is covered by the
# Test Kitchen integration suites instead; these specs exercise the
# library classes directly.

# Anchored to this file rather than to the working directory, so the suite
# runs from anywhere. Sorted because glob order is filesystem order, and a
# library referring to another at load time should not depend on luck.
Dir[File.expand_path('../libraries/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
  config.order = 'random'
end
