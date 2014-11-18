define :set_limits, :type => nil, :item => nil, :value => nil do
  limit = {
    'domain' => params[:name],
    'type' => params[:type],
    'item' => params[:item],
    'value' => params[:value]
  }

  r = nil
  begin
    r = resources(:limits_config => params[:name])
  rescue Chef::Exceptions::ResourceNotFound
    r = limits_config params[:name] do
      limits []
    end
  end
  r.limits << limit unless r.limits.detect {|l| l == limit }
end
