default['setup']['owner'] = 'nobody'
default['setup']['group'] = value_for_platform_family(
  'debian' => 'nogroup',
  'default' => 'nobody'
)
