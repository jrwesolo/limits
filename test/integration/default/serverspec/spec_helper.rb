require 'serverspec'

RSpec.configure do |config|
  config.order = 'random'
end

set :backend, :exec
