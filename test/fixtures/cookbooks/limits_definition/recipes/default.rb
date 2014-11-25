set_limits 'nobody' do
  type '-'
  item 'nofile'
  value '4096'
end

set_limits 'nobody' do
  type 'hard'
  item 'nproc'
  value '1024'
end
