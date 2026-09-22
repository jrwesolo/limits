module Limits
  module Helpers
    # Convert value into integer if applicable. The anchors are \A and \z
    # rather than ^ and $, which in Ruby match at line boundaries: a value
    # carrying a newline would otherwise match on one of its lines and be
    # coerced as a whole, turning "foo\n10" into 0 and "10\nfoo" into 10.
    # Such a value is rejected as a field instead, since limits.conf has no
    # line continuation and no value can span lines.
    def self.normalize_value(val)
      (val.is_a?(String) && val.match?(/\A-?\d+\z/)) ? val.to_i : val
    end

    # True when the given field can be written into a limits file and read
    # back as the same field.
    def self.valid_field?(val)
      Limits::FIELD.match?(val.to_s)
    end

    # Raises unless the given field can survive a round trip. The resources
    # ask the same question through valid_field? and report it as a property
    # validation failure, which is what a user should ever see. This guards
    # the point past which bad input stops being recoverable, and covers
    # anything reaching the library another way.
    def self.validate_field!(name, val)
      return val if valid_field?(val)

      raise ArgumentError,
            "#{name} #{val.inspect} cannot be written to a limits file: a " \
            "field cannot be empty or contain whitespace or '#'"
    end

    # Removing leading '#' and optional space from each line.
    def self.normalize_comment(comment)
      return unless comment

      lines = comment.lines.map(&:chomp)
      lines.map! { |line| line.sub(/^#[ \t]?/, '') }
      lines.push('') if comment.end_with?("\n")
      lines.join("\n")
    end

    # Ensure each line of comment starts with '#' followed by a space if
    # there is anything afterwards. Trailing whitespace is also removed.
    # Comment will always end in a newline for proper formatting.
    def self.format_comment(comment)
      return unless comment

      lines = comment.lines.map(&:chomp)
      lines.push('') if comment.end_with?("\n")
      lines.map! { |line| line.prepend('# ').rstrip }
      lines.join("\n").concat("\n")
    end

    # Return an array of hashes representing 'limit' resources for a
    # given run_context and path. Each hash will be compatible with
    # the format of the Limits::Entry.id method.
    def self.find_in_run_context(run_context, path)
      entries = []
      run_context.resource_collection.each do |r|
        if r.resource_name == :limit && r.path == path
          entries << { domain: r.domain, type: r.type, item: r.item }
        end
      end
      entries
    end
  end
end
