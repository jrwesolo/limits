unified_mode true

# Both names match what Chef derives from the cookbook and filename
# (limits + file.rb). They are declared anyway so the public DSL name is
# stated outright rather than being an accident of the filename.
resource_name :limits_file
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

  # Named limits rather than file, because a local called file would
  # shadow the file resource declared below.
  limits = Limits::File.new(new_resource.path)
  unmanaged = limits.reject { |entry| managed.include?(entry.id) }

  # Purge acts only when there is something to purge, so a file whose
  # limits are all declared is left alone rather than reformatted by an
  # action that was not asked to create anything.
  return if unmanaged.empty?

  unmanaged.each { |entry| limits.delete(entry) }

  # Through Chef's file resource for the same reasons the create action
  # uses it. Writing directly meant one full rewrite of the file per
  # removed limit, no backup for a user who asked for one, no owner,
  # group or mode on a file managed by this action alone, and no content
  # diff in the run output for the one action whose whole job is deleting
  # configuration somebody else wrote.
  file new_resource.path do
    content limits.to_s
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    backup new_resource.backup
  end
end

action :delete do
  file new_resource.path do
    action :delete
  end
end
