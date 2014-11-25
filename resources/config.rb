actions :create, :delete
default_action :create

attribute :name, kind_of: String, name_attribute: true
attribute :limits, kind_of: Array, default: []
attribute :system, kind_of: [TrueClass, FalseClass], default: false
