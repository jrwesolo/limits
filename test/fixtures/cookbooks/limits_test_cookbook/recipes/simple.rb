set_limit 'system for hard nofiles' do
  domain '*'
  type 'hard'
  item 'nofile'
  value 12_345
  use_system true
end

set_limit 'system for soft nofiles' do
  domain '*'
  type 'soft'
  item 'nofile'
  value 5678
  use_system true
end

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

