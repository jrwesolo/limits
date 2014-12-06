set_limit '*' do
  type 'hard'
  item 'nofile'
  value 12_345
  use_system true
end

set_limit '*' do
  type 'soft'
  item 'nofile'
  value 5678
  use_system true
end
