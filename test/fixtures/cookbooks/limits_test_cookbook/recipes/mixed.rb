limits_config 'mixed' do
  limits [
    { domain: 'a', type: 'hard', item: 'nofile', value: 123 },
    { domain: 'b', type: '-', item: 'nice', value: 456 },
    { domain: 'c', type: 'hard', item: 'niceeee', value: 123 },
    { domain: 'd', type: 'softish', item: 'nproc', value: 456 }
  ]
end
