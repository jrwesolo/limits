module Limits
  # LWRP helpers for limits
  module Helper
    # http://linux.die.net/man/5/limits.conf
    # Using the 'unless defined?' pattern to avoid
    # warnings about constants already being defined.
    TYPES = %w(hard soft -) unless defined?(TYPES)
    ITEMS = %w(core data fsize memlock nofile rss stack
               cpu nproc as maxlogins maxsyslogins priority
               locks sigpending msgqueue nice rtprio) unless defined?(ITEMS)

    def validate_limit(domain, type, item = nil, _value = nil)
      domain && !domain.empty? &&
        TYPES.include?(type) &&
        (item.nil? || ITEMS.include?(item))
    end

    def safe_str_length(str)
      str.respond_to?(:to_s) ? str.to_s.length : 0
    end

    def process_limits(limits = [])
      valid = []
      invalid = []

      limits.each do |l|
        if validate_limit(l[:domain], l[:type], l[:item], l[:value])
          valid << l
        else
          invalid << l
        end
      end

      { valid: format_limits(valid), invalid: format_limits(invalid) }
    end

    def format_limits(limits)
      max_d = limits.map { |l| safe_str_length(l[:domain]) }.max
      max_t = limits.map { |l| safe_str_length(l[:type]) }.max
      max_i = limits.map { |l| safe_str_length(l[:item]) }.max

      formatted = []
      limits.each do |l|
        formatted << format("%-#{max_d}s %-#{max_t}s %-#{max_i}s %s",
                            l[:domain], l[:type], l[:item], l[:value])
      end
      formatted
    end
  end # Helper
end # Limits
