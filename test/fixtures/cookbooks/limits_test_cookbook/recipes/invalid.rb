limits_config 'invalid_with_extension.conf' do
  limits [
    { domain: 'phil', type: 'squishy', item: 'maxlogins', value: 5 },
    { domain: 'kyle', type: 'softish', item: 'nproc', value: 678 }
  ]
end
