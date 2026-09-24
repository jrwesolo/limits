require_relative '../spec_helper'

describe Limits::Helpers do
  describe '.normalize_value' do
    # The multi-line cases fail today. The match is anchored with ^ and $,
    # which in Ruby bind to line boundaries rather than to the ends of the
    # string, so a value with a newline in it can match on one of its lines
    # and then be coerced as a whole:
    #
    #   normalize_value("10\nfoo") # => 10,  the rest of the value is lost
    #   normalize_value("foo\n10") # => 0,   String#to_i gives up at 'f'
    #
    # Neither value is numeric, so both should come back untouched and be
    # written as-is, which is what the round trip specs then reject.
    #
    # '007' coercing to 7 is intended rather than incidental. The file is
    # rewritten with the shorter literal, which pam reads identically
    # because it parses values with strtol, and both sides of a comparison
    # normalize the same way, so it does not churn.
    #
    # A value padded with whitespace stays a String, which is what lets the
    # field guard reject it rather than have it silently coerced.
    values = {
      'One' => 'One',
      '1' => 1,
      1 => 1,
      '1.0' => '1.0',
      '+1' => '+1',
      '-1' => -1,
      1.0 => 1.0,
      nil => nil,
      "10\nfoo" => "10\nfoo",
      "foo\n10" => "foo\n10",
      "10\n" => "10\n",
      '007' => 7,
      ' 1' => ' 1',
      '1 ' => '1 ',
    }

    values.each do |value, expected|
      it value.inspect do
        normalized = subject.normalize_value(value)
        expect(normalized).to eq(expected)
      end
    end
  end

  # Trailing whitespace comes off because format_comment takes it off
  # everything it writes. A '#' does not, because a comment holds its own
  # text: the marker belongs to the file, and taking it off again is
  # unformat_comment's job. That split is what makes this idempotent, which
  # it has to be, since Chef runs it over the value a recipe gives and over
  # the value read back off disk on its way into the same property.
  describe '.normalize_comment' do
    comments = {
      'Hello' => 'Hello',
      'Hello ' => 'Hello',
      "Hello\t" => 'Hello',
      '   ' => '',
      "Hello\n" => "Hello\n",
      "Hello\nWorld" => "Hello\nWorld",
      "Hello\nWorld\n" => "Hello\nWorld\n",
      "Hello \nWorld\n" => "Hello\nWorld\n",
      "Hello\n\nWorld\n\n" => "Hello\n\nWorld\n\n",
      ' Hello' => ' Hello',
      '#Hello' => '#Hello',
      '# Hello' => '# Hello',
      '## Hello' => '## Hello',
      '#1 priority' => '#1 priority',
      nil => nil,
    }

    comments.each do |comment, expected|
      it comment.inspect do
        normalized = subject.normalize_comment(comment)
        expect(normalized).to eq(expected)
      end
    end

    it 'is idempotent for every case above' do
      comments.each_key do |comment|
        once = subject.normalize_comment(comment)
        expect(subject.normalize_comment(once)).to eq(once)
      end
    end
  end

  # The inverse of format_comment, and the only place a '#' means syntax.
  # Exactly one marker comes off each line because exactly one goes on, so
  # a comment whose own text starts with a '#' comes back carrying it.
  # Whitespace in front of the marker is layout from a hand-edited file and
  # goes with it, while whitespace after it is the comment's own.
  describe '.unformat_comment' do
    comments = {
      '# Hello' => 'Hello',
      '#Hello' => 'Hello',
      "#\tHello" => 'Hello',
      '#  Hello' => ' Hello',
      '# # Hello' => '# Hello',
      '# #1 priority' => '#1 priority',
      '#' => nil,
      "#\t" => nil,
      '  # Hello' => 'Hello',
      "\t# Hello" => 'Hello',
      '  #   Hello' => '  Hello',
      '  #Hello' => 'Hello',
      "# Hello\n  # World" => "Hello\nWorld",
      "# Hello\n# World" => "Hello\nWorld",
      '# Hello  ' => 'Hello',
      nil => nil,
    }

    comments.each do |comment, expected|
      it comment.inspect do
        expect(subject.unformat_comment(comment)).to eq(expected)
      end
    end

    # The round trip that matters: what format_comment writes, this reads
    # back, for any comment already in canonical form.
    ['Hello', ' Hello', '# Hello', '#1 priority', "Hello\nWorld", "Hello\n"].each do |canonical|
      it "undoes format_comment for #{canonical.inspect}" do
        written = subject.format_comment(canonical)
        expect(subject.unformat_comment(written.chomp)).to eq(canonical)
      end
    end
  end

  describe '.format_comment' do
    comments = {
      'Hello' => "# Hello\n",
      'Hello ' => "# Hello\n",
      "Hello\n" => "# Hello\n#\n",
      "Hello\nWorld" => "# Hello\n# World\n",
      "Hello\nWorld\n" => "# Hello\n# World\n#\n",
      "Hello \nWorld\n" => "# Hello\n# World\n#\n",
      "Hello\n\nWorld\n\n" => "# Hello\n#\n# World\n#\n#\n",
      ' Hello' => "#  Hello\n",
      '  Hello' => "#   Hello\n",
      '# Hello' => "# # Hello\n",
      nil => nil,
    }

    comments.each do |comment, expected|
      it comment.inspect do
        formatted = subject.format_comment(comment)
        expect(formatted).to eq(expected)
      end
    end
  end

  describe '.find_in_run_context' do
    # Drives which limits limits_file's :purge action keeps. Anything this
    # fails to report is treated as unmanaged and deleted from the file, so
    # both halves of the filter matter: the resource has to be a limit, and
    # it has to be one for the path being purged.
    #
    # A limit resource carries the four attributes read here. The stand-in
    # for another resource deliberately has no path, so the specs fail
    # loudly if the resource_name check ever stops short-circuiting.
    limit = Struct.new(:resource_name, :path, :domain, :type, :item)
    other = Struct.new(:resource_name)

    let(:resources) do
      [
        limit.new(:limit, '/etc/security/limits.conf', 'user1', 'hard', 'nofile'),
        limit.new(:limit, '/etc/security/limits.conf', 'user2', 'soft', 'nproc'),
        limit.new(:limit, '/etc/security/limits.d/100.conf', 'user3', '-', 'cpu'),
        other.new(:file),
        other.new(:limits_file),
      ]
    end

    let(:run_context) { Struct.new(:resource_collection).new(resources) }

    it 'reports the limits for the given path' do
      found = subject.find_in_run_context(run_context, '/etc/security/limits.conf')

      expect(found).to eq(
        [
          { domain: 'user1', type: 'hard', item: 'nofile' },
          { domain: 'user2', type: 'soft', item: 'nproc' },
        ]
      )
    end

    it 'reports limits for another path separately' do
      found = subject.find_in_run_context(run_context, '/etc/security/limits.d/100.conf')

      expect(found).to eq([{ domain: 'user3', type: '-', item: 'cpu' }])
    end

    it 'reports nothing for a path with no limits' do
      found = subject.find_in_run_context(run_context, '/etc/security/limits.d/404.conf')

      expect(found).to be_empty
    end

    it 'reports nothing when the run context holds no resources' do
      empty = Struct.new(:resource_collection).new([])

      expect(subject.find_in_run_context(empty, '/etc/security/limits.conf')).to be_empty
    end
  end
end
