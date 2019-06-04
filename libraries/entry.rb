module Limits
  # Represents a limit in a limits.conf file
  class Entry
    include Comparable

    attr_reader :domain,
                :type,
                :item,
                :value,
                :comment

    def initialize(domain, type, item, value = nil, comment = nil)
      @domain = domain
      @type = type
      @item = item
      @value = Limits::Helpers.normalize_value(value)
      @comment = Limits::Helpers.normalize_comment(comment)
    end

    def id
      { domain: @domain, type: @type, item: @item }
    end

    def columns
      [@domain, @type, @item, @value].map { |x| x.to_s.length }
    end

    def to_s
      fields = [@domain, @type, @item, @value].compact.map(&:to_s)
      fields.push("(#{@comment.gsub(/\n/, '\n')})") if @comment
      fields.join(' ')
    end

    def format(columns = nil, spacing = 4)
      fields = [@domain, @type, @item, @value].compact.map(&:to_s)

      if columns
        # Left-align fields according to provided columns
        fields = [fields, columns[0, fields.length]].transpose.map do |item, length|
          item.ljust(length)
        end
      end

      str = @comment ? Limits::Helpers.format_comment(@comment) : ''
      str << fields.join(' ' * spacing).rstrip
      str
    end

    # Sort entries based on the following criteria:
    # 1) existence of comment
    # 2) domain
    # 3) type
    # 4) item
    # For simplicity, values that can't be
    # compared will be considered equal.
    def <=>(other)
      a = [@comment ? 0 : 1, @domain, @type, @item]
      b = [other.comment ? 0 : 1, other.domain, other.type, other.item]

      # iterate over each pair for comparison
      [a, b].transpose.each do |cmp_a, cmp_b|
        val = cmp_a <=> cmp_b
        return val unless val == 0 || val.nil?
      end

      0 # entries are equivalent
    end
  end
end
