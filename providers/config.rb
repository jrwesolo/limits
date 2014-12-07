Chef::Provider.send(:include, Limits::Helper)

# needed so notifications work correctly
use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do
  directory "conf directory for #{new_resource.name}" do
    path node['limits']['conf_dir']
    owner 'root'
    group 'root'
    mode 0755
    recursive true
    action :create
    not_if { new_resource.use_system }
  end

  results = process_limits(new_resource.limits)

  template template_target do
    cookbook 'limits'
    source 'limits.d.conf.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables valid_limits: results[:valid],
              invalid_limits: results[:invalid]
    action :create
  end
end

action :delete do
  file template_target do
    action :delete
  end
end

def template_target
  if new_resource.use_system
    node['limits']['system_conf']
  else
    ::File.join(node['limits']['conf_dir'],
                resolve_filename(new_resource.filename))
  end
end

def resolve_filename(filename)
  result = filename.strip.gsub(/[^0-9A-Za-z.\-]/, '_').squeeze('_')
  result.end_with?('.conf') ? result : result << '.conf'
end
