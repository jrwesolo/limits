if defined?(ChefSpec)
  def create_limits_config(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:limits_config,
                                            :create,
                                            resource_name)
  end

  def delete_limits_config(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:limits_config,
                                            :delete,
                                            resource_name)
  end
end
