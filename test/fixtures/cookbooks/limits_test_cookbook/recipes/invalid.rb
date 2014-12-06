limits_config 'invalid.conf' do
  limits [
    { domain: 'phil', type: 'squishy', item: 'maxlogins', value: 5 },
    { domain: 'kyle', type: 'softish', item: 'nproc', value: 678 }
  ]
end
