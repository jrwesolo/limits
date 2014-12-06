require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
  config.order = 'random'
end

ChefSpec::Coverage.start!
