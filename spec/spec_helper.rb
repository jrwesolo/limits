# require 'chefspec'
# require 'chefspec/berkshelf'

Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
  config.order = 'random'
end
