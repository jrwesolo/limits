unified_mode true

# Chef would derive limits_limit from the cookbook and filename. provides
# exposes the shorter DSL name, and resource_name makes converge output
# report it as `limit` to match.
resource_name :limit
provides :limit

property :path,
         String,
         default: '/etc/security/limits.conf',
         identity: true,
         callbacks: { 'should not be empty' => ->(x) { !x.empty? } }

# The field callbacks ask the same question Limits::Entry raises on, so
# that a user sees a property validation failure naming the property
# rather than an error out of the library. A field carrying whitespace or
# a '#' cannot be written into a limits file and read back: the parser
# here and pam_limits both split fields on whitespace and end the line at
# a '#', so such a limit is silently dropped or silently altered.
field = { 'should not contain whitespace or #' => ->(x) { Limits::Helpers.valid_field?(x) } }

property :domain,
         String,
         required: true,
         identity: true,
         callbacks: { 'should not be empty' => ->(x) { !x.empty? } }.merge(field)

property :type,
         String,
         equal_to: Limits::TYPES,
         required: true,
         identity: true

property :item,
         String,
         equal_to: Limits::ITEMS,
         required: true,
         identity: true

property :value,
         [Integer, String],
         required: [:create],
         coerce: proc { |x| Limits::Helpers.normalize_value(x) },
         callbacks: { 'should not be empty' => ->(x) { !x.to_s.empty? } }.merge(field)

property :comment,
         String,
         coerce: proc { |x| Limits::Helpers.normalize_comment(x) },
         callbacks: { 'should not be empty' => ->(x) { !x.empty? } }

default_action :create

load_current_value do
  # find existing entry or abort
  search = Limits::Entry.new(domain, type, item)
  file = Limits::File.new(path)
  index = file.index(search)
  current_value_does_not_exist! unless index

  # load current values that are not 'identity' properties
  current = file.at(index)
  value current.value
  comment current.comment
end

action :create do
  converge_if_changed do
    # This is needed to properly use the comment from
    # the current resource when no comment was passed
    # into the new resource.
    derived_comment = if !property_is_set?(:comment) && current_resource
                        current_resource.comment
                      else
                        new_resource.comment
                      end

    entry = Limits::Entry.new(
      new_resource.domain,
      new_resource.type,
      new_resource.item,
      new_resource.value,
      derived_comment
    )

    limits = Limits::File.new(new_resource.path)
    limits.add(entry)
    write_limits(limits)
  end
end

action :delete do
  if current_resource
    converge_by "delete #{current_resource.identity}" do
      entry = Limits::Entry.new(
        current_resource.domain,
        current_resource.type,
        current_resource.item
      )

      limits = Limits::File.new(current_resource.path)
      limits.delete(entry)
      write_limits(limits)
    end
  end
end

action_class do
  # Hand the rendered file to Chef's file resource rather than writing it
  # here.
  #
  # Run rather than declared, against a run context whose event dispatcher
  # has nothing subscribed to it, the way Chef runs a guard resource in
  # Chef::GuardInterpreter::ResourceGuardInterpreter. A limit is declared
  # once per limit, so a declared file resource would print one diff of the
  # whole file per limit, and converge_if_changed already reports the
  # change a reader cares about.
  #
  # The context gets clone(freeze: false) of the node. Not the node itself,
  # because RunContext#node= reassigns node.run_context and would leave the
  # rest of the run pointing here (chef/chef#3485). Not a dup, because dup
  # drops the singleton class, where ChefSpec defines the #runner method its
  # run_action calls, so step_into on this resource would raise. And
  # freeze: false so that a node a recipe has frozen still yields a
  # writable copy, since RunContext#node= writes to it.
  # docs/agents/chef-resources.md has the longer account.
  #
  # backup false, and no owner, group or mode. This resource writes the
  # whole file once per limit, and permissions and backups belong to
  # limits_file.
  def write_limits(limits)
    quiet_run_context = Chef::RunContext.new(
      node.clone(freeze: false),
      {},
      Chef::EventDispatch::Dispatcher.new
    )

    written = Chef::Resource::File.new(limits.path, quiet_run_context)
    written.content(limits.to_s)
    written.backup(false)
    written.run_action(:create)
  end
end
