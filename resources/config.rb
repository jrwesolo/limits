actions :create, :delete
default_action :create

attribute :name,
          :kind_of => String,
          :required => true,
          :name_attribute => true
attribute :limits,
          :kind_of => Array,
          :default => []
attribute :system,
          :kind_of => [TrueClass, FalseClass],
          :default => false
