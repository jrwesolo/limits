set_limit 'alice' do
  type 'hard'
  item 'nofile'
  value 500
end

set_limit 'alice is nice' do
  filename 'alice'
  domain 'alice'
  type 'soft'
  item 'nofile'
  value 250
end

limits_config 'stanley' do
  action :delete
end
