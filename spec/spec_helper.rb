# Required here rather than from the specs that use it, and this matters.
# ChefSpec's RSpec integration is a config.include, and RSpec applies a
# module added after a group already exists by injecting it into that
# group. Its API defines a default `subject` of the Chef run, so requiring
# ChefSpec from a spec file loaded after spec/libraries would override the
# subject those groups had already declared, and `describe 'Limits::ITEMS'`
# would go looking for a cookbook named Limits.
require 'chefspec'

# Anchored to this file rather than to the working directory, so the suite
# runs from anywhere. Sorted because glob order is filesystem order, and a
# library referring to another at load time should not depend on luck.
Dir[File.expand_path('../libraries/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
  config.order = 'random'
end
