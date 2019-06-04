module Limits
  # Represents a collection of entries as a limits.conf file
  class File
    include Enumerable

    attr_reader :path

    def initialize(path)
      @path = path
      @entries = []

      if ::File.exist?(path)
        ::File.read(path).scan(Limits::REGEX) do |match|
          groups = Hash[::Limits::REGEX.names.zip(match)]

          # remove end newline on comment for formatting
          groups['comment'].chomp! if groups['comment']

          add(Limits::Entry.new(groups['domain'],
                                groups['type'],
                                groups['item'],
                                groups['value'],
                                groups['comment']))
        end
      end
    end

    def index(entry)
      @entries.index { |e| entry.id == e.id }
    end

    def at(idx)
      @entries.at(idx)
    end

    def write!
      ::File.open(@path, 'w') { |file| file.write(self) }
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
      str = "# #{@path}\n#\n# This file is managed by Chef\n# Local changes may be lost!\n"

      last_had_comment = true
      @entries.sort.each do |entry|
        str << "\n" if entry.comment || last_had_comment
        str << entry.format(columns)
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
