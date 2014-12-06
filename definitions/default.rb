define :set_limit, use_system: false, # ~FC015
                   filename: nil,
                   domain: nil,
                   type: nil,
                   item: nil,
                   value: nil do
  if params[:use_system]
    params[:filename] = 'system'
  else
    params[:filename] ||= params[:name]
  end

  limit = {
    domain: params[:domain] || params[:name],
    type: params[:type],
    item: params[:item],
    value: params[:value]
  }

  r = nil
  begin
    r = resources(limits_config: params[:filename])
  rescue Chef::Exceptions::ResourceNotFound
    r = limits_config params[:filename] do
      limits []
      use_system params[:use_system]
      action :create
    end
  end
  r.limits << limit unless r.limits.any? { |l| l == limit }
end
