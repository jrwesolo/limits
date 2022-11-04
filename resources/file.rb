unified_mode true if Chef::VERSION.to_f >= 15.3

resource_name :limits_file # backwards-compatibility for Chef < 16
provides :limits_file

property :path, String, name_property: true
property :owner, [String, Integer], default: 'root'
property :group, [String, Integer], default: 'root'
property :mode, [String, Integer], default: '0644'
property :backup, [Integer, FalseClass], default: false

default_action :create

action :create do
  file new_resource.path do
    content Limits::File.new(new_resource.path).to_s
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    backup new_resource.backup
  end
end

action :purge do
  managed = Limits::Helpers.find_in_run_context(
    run_context.root_run_context,
    new_resource.path
  )

  file = Limits::File.new(new_resource.path)
  unmanaged = file.select { |entry| !managed.include?(entry.id) }

  unmanaged.each do |entry|
    converge_by "delete #{entry.id}" do
      file.delete(entry)
      file.write!
    end
  end
end

action :delete do
  file new_resource.path do
    action :delete
  end
end
