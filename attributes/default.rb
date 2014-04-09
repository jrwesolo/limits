# for system limits.conf
default['limits']['system_conf'] = File.join('/', 'etc', 'security', 'limits.conf')
default['limits']['system_limits'] = []

# for limits.d
default['limits']['conf_dir'] = File.join('/', 'etc', 'security', 'limits.d')
