actions :create, :delete
default_action :create

attribute :filename, kind_of: String, name_attribute: true
attribute :limits, kind_of: Array, default: []
attribute :use_system, kind_of: [TrueClass, FalseClass], default: false
