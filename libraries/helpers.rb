module Limits
  module Helpers
    # Convert value into integer if applicable
    def self.normalize_value(val)
      (val.is_a?(String) && val =~ /^-?\d++$/) ? val.to_i : val
    end

    # Removing leading '#' and optional space from each line.
    def self.normalize_comment(comment)
      return nil unless comment

      lines = comment.lines.map(&:chomp)
      lines.map! { |line| line.sub(/^#[ \t]?/, '') }
      lines.push('') if comment.end_with?("\n")
      lines.join("\n")
    end

    # Ensure each line of comment starts with '#' followed by a space if
    # there is anything afterwards. Trailing whitespace is also removed.
    # Comment will always end in a newline for proper formatting.
    def self.format_comment(comment)
      return nil unless comment

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
