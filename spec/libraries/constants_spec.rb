require_relative '../spec_helper'

# Limits::REGEX is what the cookbook knows about the file format. Every
# other question, whether a limit already exists, what its value is, which
# limits are unmanaged and can be purged, is answered by what this matches
# and what it quietly skips.
#
# Until now it was only exercised through one heredoc in the file specs,
# where a line such as 'invalid limit' meant "this must not parse" and
# nothing said so. These examples state the rules directly.
describe Limits::REGEX do
  # Returns the captures of the first match in the given text, or nil when
  # nothing in it parses as a limit.
  def parse(text)
    match = Limits::REGEX.match(text)
    return unless match

    Hash[match.names.map { |name| [name.to_sym, match[name]] }]
  end

  describe 'A line that parses' do
    parses = {
      'a plain limit' => 'user hard nofile 1024',
      'leading spaces' => '   user hard nofile 1024',
      'leading tabs' => "\tuser hard nofile 1024",
      'tab separators' => "user\thard\tnofile\t1024",
      'mixed separators' => "user \t hard   nofile\t1024",
      'aligned columns' => 'user    hard    nofile    1024',
      'trailing spaces' => "user hard nofile 1024   \n",
      'a trailing tab' => "user hard nofile 1024\t\n",
    }

    parses.each do |description, line|
      it "matches #{description}" do
        expect(parse(line)).to include(
          domain: 'user',
          type: 'hard',
          item: 'nofile',
          value: '1024'
        )
      end
    end
  end

  describe 'A line that does not parse' do
    # Each of these is skipped in silence. Limits::File#initialize scans
    # rather than iterating lines, so an unparseable line is not an error,
    # it simply contributes no entry and is dropped the next time the file
    # is written.
    skipped = {
      'too few fields' => 'user hard nofile',
      'too many fields' => 'user hard nofile 1024 extra',
      'a comment with no limit under it' => "# just a comment\n",
      'an empty line' => "\n",
      'only whitespace' => "   \t\n",
    }

    skipped.each do |description, line|
      it "skips #{description}" do
        expect(parse(line)).to be_nil
      end
    end
  end

  describe 'Domains' do
    # The syntax pam_limits accepts, as documented in limits.conf(5): a
    # username, a group, the wildcard, the percent wildcard for maxlogins,
    # and uid or gid ranges. The regex takes any of them because it asks
    # only that a field carry no whitespace and no '#'.
    domains = %w(user @student * %student %group:100 1000:1010 @1000:1010 1000:)

    domains.each do |domain|
      it "matches #{domain}" do
        expect(parse("#{domain} hard nofile 1024")).to include(domain: domain)
      end
    end
  end

  describe 'Types and values' do
    it 'matches the - type, which sets both the soft and hard limit' do
      expect(parse('user - nofile 1024')).to include(type: '-')
    end

    it 'matches a word value such as unlimited' do
      expect(parse('user hard nofile unlimited')).to include(value: 'unlimited')
    end

    it 'matches a negative value' do
      expect(parse('user hard nice -20')).to include(value: '-20')
    end
  end

  describe 'Comments' do
    it 'captures a comment attached to the limit below it' do
      expect(parse("# a note\nuser hard nofile 1024")).to include(
        comment: "# a note\n",
        domain: 'user'
      )
    end

    it 'captures a multi-line comment as one comment' do
      expect(parse("# first\n# second\nuser hard nofile 1024")).to include(
        comment: "# first\n# second\n"
      )
    end

    it 'captures an indented comment' do
      expect(parse("\t# a note\nuser hard nofile 1024")).to include(
        comment: "\t# a note\n"
      )
    end

    it 'captures an inline comment separately from the value' do
      expect(parse('user hard nofile 1024 # a note')).to include(
        value: '1024',
        inline_comment: '# a note'
      )
    end

    it 'ends the value at a # with no space before it' do
      # Worth pinning because pam_limits agrees: it cuts the line at the
      # first '#' wherever it falls, so both read the value as 1024.
      expect(parse('user hard nofile 1024# a note')).to include(
        value: '1024',
        inline_comment: '# a note'
      )
    end

    it 'does not attach a comment separated by a blank line' do
      expect(parse("# a note\n\nuser hard nofile 1024")).to include(
        comment: nil,
        domain: 'user'
      )
    end
  end

  describe 'Line endings' do
    it 'parses a line ending in a newline' do
      expect(parse("user hard nofile 1024\n")).to include(value: '1024')
    end

    # Worth stating because the consequence is out of all proportion to the
    # cause. A '\r' is whitespace, so it falls outside the value capture,
    # and the '$' then has a stray character in front of it. Every line of
    # a CRLF file fails the same way, so the file parses as no limits at
    # all: every managed limit looks absent, and every unmanaged line is
    # erased the next time the file is written.
    #
    # Exotic on Linux, but reachable through an editor on Windows or a
    # template rendered with CRLF endings. Pinned as known behaviour rather
    # than endorsed.
    it 'does not parse a line with CRLF endings' do
      expect(parse("user hard nofile 1024\r\n")).to be_nil
    end

    it 'finds nothing at all in a CRLF file' do
      contents = "user1 hard nofile 1024\r\nuser2 soft nproc 20\r\n"

      expect(contents.scan(Limits::REGEX)).to be_empty
    end
  end

  describe 'Scanning a whole file' do
    let(:contents) do
      <<~'EOF'
        # a note
        user1 hard nofile 1024

        user2 - nproc 20 # inline
        not a limit
        user3 soft cpu 50
      EOF
    end

    it 'finds every limit and nothing else' do
      domains = contents.scan(Limits::REGEX).map do |match|
        Hash[Limits::REGEX.names.zip(match)]['domain']
      end

      expect(domains).to eq(%w(user1 user2 user3))
    end
  end
end
