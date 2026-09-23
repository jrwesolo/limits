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

    # The canonical form of a comment: its text, with trailing whitespace
    # taken off every line.
    #
    # This is what the comment property coerces to, and Chef runs that
    # coercion on both sides of the comparison a limit makes, since
    # load_current_value assigns the comment it read back into the same
    # property. Anything lossy here would therefore have to be lossy twice
    # over and give the same answer, so this does one thing only, and
    # rstrip is idempotent.
    #
    # Trailing whitespace goes because format_comment strips it from every
    # line it writes. A comment keeping it would never equal the one read
    # back, and the limit would rewrite the file on every run to arrive at
    # the file it already had.
    #
    # Taking a '#' off is deliberately not done here. That is what
    # unformat_comment is for, and it belongs to reading a file rather than
    # to reading a recipe.
    def self.normalize_comment(comment)
      return unless comment

      lines = comment.lines.map(&:chomp)
      lines.map!(&:rstrip)
      lines.push('') if comment.end_with?("\n")
      lines.join("\n")
    end

    # Undoes format_comment, turning the lines of a comment as a file spells
    # them back into the comment itself. The inverse of writing it, and the
    # only place a '#' is understood as syntax rather than as text.
    #
    # Exactly one marker comes off each line, because exactly one goes on.
    # A comment whose own text begins with a '#' therefore survives: it is
    # written as '# # note' and read back as '# note'.
    #
    # Anchored with \A rather than '^', which in Ruby matches at every line
    # boundary. Each line is already separate here, so the two behave alike
    # today, but only by accident of the call site: handed a whole comment,
    # '^' would take a '#' off any line in it. That assumption is what made
    # normalize_value read "foo\n10" as a number. There is no end anchor,
    # because this takes a prefix off rather than matching a whole line, and
    # a '\z' would strip the marker only from a line carrying nothing else.
    #
    # What is left is then normalized like any other comment, so a comment
    # read out of a file is in exactly the form the comment property
    # coerces to, and the two can be compared.
    def self.unformat_comment(comment)
      return unless comment

      text = normalize_comment(comment.lines.map { |line| line.sub(/\A#[ \t]?/, '') }.join)

      # A marker with nothing after it is no comment at all. Read back as
      # '', it would reach the comment property through load_current_value
      # and fail the property's own check, and format_comment would write
      # it out as a blank line rather than a comment.
      text unless text.empty?
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
