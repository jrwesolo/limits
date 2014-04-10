def validate_limits(limits = [])
  valid = []
  invalid = []

  # http://linux.die.net/man/5/limits.conf
  valid_type = %w(hard soft -)
  valid_item = %w(core data fsize memlock
                  nofile rss stack cpu nproc
                  as maxlogins maxsyslogins
                  priority locks sigpending
                  msgqueue nice rtprio)

  limits.each do |limit|
    if valid_type.include?(limit['type']) &&
       valid_item.include?(limit['item']) &&
       limit['domain'] && !limit['domain'].empty? &&
       limit['value'] && !limit['value'].empty?
      valid << limit
    else
      Chef::Log.warn("Invalid limit detected: #{limit.inspect}")
      invalid << limit
    end
  end

  [format_limits(valid), format_limits(invalid)]
end

private

def format_limits(limits)
  max_domain = limits.map { |l| l['domain'].nil? ? 0 : l['domain'].length }.max
  max_type = limits.map { |l| l['type'].nil? ? 0 : l['type'].length }.max
  max_item = limits.map { |l| l['item'].nil? ? 0 : l['item'].length }.max
  max_value = limits.map { |l| l['value'].nil? ? 0 : l['value'].length }.max

  formatted = []
  limits.each do |limit|
    formatted << format("%-#{max_domain}s  %-#{max_type}s  %-#{max_item}s  %-#{max_value}s",
                        limit['domain'], limit['type'], limit['item'], limit['value'])
  end
  formatted
end
