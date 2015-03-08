
node[:limits][:files].each do |filename, limits|
  limits.each do |l|
    set_limit filename do
      domain l[:domain] || filename
      type l[:type]
      item l[:item]
      value l[:value]
      use_system filename.to_s == 'system'
    end
  end
end
