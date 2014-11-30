limits_config '!!!sanitized   name #####' do
  limits [
    { domain: 'a', type: 'hard', item: 'nofile', value: 50_000 },
    { domain: 'b', type: '-', item: 'nice', value: 5000 },
    { domain: 'user1', type: 'soft', item: 'priority', value: 500 }
  ]
end

limits_config 'valid_and_invalid' do
  limits [
    { domain: 'a', type: 'hard', item: 'nofile', value: 123 },
    { domain: 'b', type: '-', item: 'nice', value: 456 },
    { domain: 'c', type: 'hard', item: 'niceeee', value: 123 },
    { domain: 'd', type: 'softish', item: 'nproc', value: 456 }
  ]
end
