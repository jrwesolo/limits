module Limits
  # Represents a collection of entries as a limits.conf file
  class File
    include Enumerable

    attr_reader :path

    def initialize(path)
      @path = path
      @entries = []

      if ::File.exist?(path)
        # Limits::REGEX is an LF grammar: it ends a line at '$', which sits
        # in front of a '\n' and not in front of the '\r' of a CRLF pair.
        # Left alone, a file written with Windows endings parses as only
        # those of its limits that carry an inline comment, since '\#.*+'
        # consumes the '\r' where nothing else does, and the rest are
        # dropped the next time the file is written. Normalizing here rather
        # than loosening the grammar keeps one definition of a line, and the
        # file is rewritten with LF.
        ::File.read(path).gsub("\r\n", "\n").scan(Limits::REGEX) do |match|
          groups = Hash[::Limits::REGEX.names.zip(match)]

          # remove end newline on comment for formatting
          groups['comment'].chomp! if groups['comment']

          # The one place a '#' is read as syntax. Everywhere else a comment
          # is already its own text: the comment property holds what a
          # recipe asked for, and an entry keeps what it was handed.
          add(Limits::Entry.new(groups['domain'],
                                groups['type'],
                                groups['item'],
                                groups['value'],
                                Limits::Helpers.unformat_comment(groups['comment'])))
        end
      end
    end

    def index(entry)
      @entries.index { |e| entry.id == e.id }
    end

    def at(idx)
      @entries.at(idx)
    end

    def add(new)
      idx = index(new)
      if idx
        @entries[idx] = new
      else
        @entries << new
      end
    end

    def delete(old)
      idx = index(old)
      @entries.delete_at(idx) if idx
    end

    def columns
      @entries.map(&:columns).transpose.map(&:max)
    end

    # Construct file with entries that are available. Entries with
    # comments will be surrounded by empty lines for readability.
    def to_s
      # The path goes through format_comment rather than into a string with
      # a '#' in front of it, because a filename may carry a newline: Linux
      # allows any byte but '/' and NUL, and pam_limits reads the files it
      # globs regardless. Written by hand, such a name would end the comment
      # and stand the rest of itself up as a line of its own, which reads
      # back as a limit nobody declared.
      str = Limits::Helpers.format_comment(
        "#{@path}\n\nThis file is managed by Chef\nLocal changes may be lost!"
      )

      # Once, rather than once per entry. columns walks every entry and
      # transposes the result, and the entries do not change while the file
      # is being rendered, so calling it inside the loop did that work n
      # times over to arrive at the same widths.
      widths = columns

      last_had_comment = true
      @entries.sort.each do |entry|
        str << "\n" if entry.comment || last_had_comment
        str << entry.format(widths)
        str << "\n"
        last_had_comment = !entry.comment.nil?
      end

      str << "\n# End of file (#{@entries.size} #{@entries.size == 1 ? 'limit' : 'limits'})\n"
      str
    end

    def each(&block)
      @entries.each(&block)
    end
  end
end
