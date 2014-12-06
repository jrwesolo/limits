limits_config 'sanitize me!' do
  limits [
    { domain: 'a', type: 'hard', item: 'nofile', value: 50_000 },
    { domain: 'b', type: '-', item: 'nice', value: 5000 },
    { domain: 'user1', type: 'soft', item: 'priority', value: 500 }
  ]
end
