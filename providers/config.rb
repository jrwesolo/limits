action :create do
  directory node['limits']['conf_dir'] do
    mode 0755
    owner 'root'
    group 'root'
    recursive true
  end unless ::File.directory?(node['limits']['conf_dir']) # CHEF-3694

  valid, invalid = validate_limits(new_resource.limits)

  if new_resource.system
    template_destination = node['limits']['system_conf']
  else
    template_destination = ::File.join(node['limits']['conf_dir'], "#{new_resource.name}.conf")
  end

  t = template template_destination do
    cookbook 'limits'
    source 'limits.d.conf.erb'
    mode 0644
    owner 'root'
    group 'root'
    variables(
      :valid_limits => valid,
      :invalid_limits => invalid
    )
    action :create
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)
end

action :delete do
  if new_resource.system
    template_destination = node['limits']['system_conf']
  else
    template_destination = ::File.join(node['limits']['conf_dir'], "#{new_resource.name}.conf")
  end

  t = template template_destination do
    cookbook 'limits'
    source 'limits.d.conf.erb'
    action :delete
  end

  new_resource.updated_by_last_action(t.updated_by_last_action?)
end
