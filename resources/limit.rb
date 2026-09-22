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

    file = Limits::File.new(new_resource.path)
    file.add(entry)
    file.write!
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

      file = Limits::File.new(current_resource.path)
      file.delete(entry)
      file.write!
    end
  end
end
