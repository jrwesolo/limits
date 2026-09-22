require 'spec_helper'

# Every entry the cookbook writes has to be readable again by the same
# parser, because that is how the cookbook finds out what is already on
# disk. Limits::File#initialize scans with Limits::REGEX, load_current_value
# indexes the result, and limits_file rebuilds the whole file from it.
#
# A line that does not match the regex is not an error anywhere. It is
# simply not seen, so the limit converges on every run and disappears the
# next time the file is rewritten.
#
# Limits::REGEX requires each of the four fields to be [^\s#]++, and the
# possessive quantifiers mean there is no backtracking to rescue a line
# with an extra field in it. Nothing upstream enforces that. Both resources
# constrain type and item with equal_to, but domain and value are only
# checked for being non-empty, so any string with a space or a '#' in it
# reaches Limits::Entry intact.
#
# There is no valid input this rejects. limits.conf is read a line at a
# time with getline and has no continuation syntax, the first three fields
# are split on whitespace, and a '#' ends the line wherever it appears, so
# a field carrying either character cannot describe a limit in the first
# place.
#
# These specs state the invariant. They fail today.
describe 'Round tripping an entry through a limits file' do
  let(:path) { 'limits.conf' }

  # Builds an entry from the fields a case cares about. Type and item
  # default to a pair that is valid everywhere, so each case only has to
  # state the field it is about.
  def entry_for(fields)
    fields = { type: 'hard', item: 'nofile' }.merge(fields)
    Limits::Entry.new(
      fields[:domain],
      fields[:type],
      fields[:item],
      fields[:value],
      fields[:comment]
    )
  end

  # Formats the given entries into a file and reads the result back,
  # exactly as a converge does: limits_file writes Limits::File#to_s, and
  # the next resource to touch the path parses it again.
  def round_trip(*entries)
    written = Limits::File.new(path)
    entries.each { |entry| written.add(entry) }
    contents = written.to_s

    allow(::File).to receive(:exist?).with(path).and_return(true)
    allow(::File).to receive(:read).with(path).and_return(contents)

    Limits::File.new(path)
  end

  before do
    allow(::File).to receive(:exist?).with(path).and_return(false)
  end

  context 'With fields that do not survive the round trip' do
    # Three of these write a line Limits::REGEX cannot match at all, so the
    # entry is silently dropped on the next read:
    #
    #   Limits::Entry.new('foo bar', 'hard', 'nofile', 10).format
    #   # => "foo bar    hard    nofile    10"
    #   Limits::REGEX.match(that) # => nil
    #
    # The fourth, a '#' in the value, is worse than it looks. The line does
    # match, because the regex treats everything from the '#' as an inline
    # comment and Limits::File discards it, so "10#20" is read back as 10
    # and the resource never reaches a steady state.
    #
    # pam_limits agrees with neither the written line nor the cookbook. It
    # splits on whitespace and cuts the line at the first '#' wherever it
    # appears, so a domain of 'foo#bar' leaves it a one field line.
    #
    # The space in a domain is the case a user hits by accident, by naming
    # a group with a space in it.
    unreadable = {
      'a domain containing a space' => { domain: 'foo bar', value: 10 },
      'a domain containing a #' => { domain: 'foo#bar', value: 10 },
      'a value containing a space' => { domain: 'foo', value: '10 20' },
      'a value containing a #' => { domain: 'foo', value: '10#20' },
    }

    unreadable.each do |description, fields|
      context "With #{description}" do
        it 'is rejected when the entry is built' do
          expect { entry_for(fields) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  context 'With unusual but valid fields' do
    # The guard above must not cost any of the syntax limits.conf actually
    # allows. These pass today and have to keep passing.
    #
    # Domains: a wildcard, a group, a user, a percent group for maxlogins,
    # a uid range, and a gid range. Values: a word, a negative number, and
    # a number written as a string.
    readable = {
      'a wildcard domain' => { domain: '*', value: 1024 },
      'a group domain' => { domain: '@student', type: 'soft', item: 'nproc', value: 20 },
      'a percent domain' => { domain: '%student', type: '-', item: 'maxlogins', value: 4 },
      'a uid range domain' => { domain: '@1000:1010', item: 'nproc', value: 30 },
      'an open ended uid range domain' => { domain: '1000:', item: 'nproc', value: 30 },
      'an unlimited value' => { domain: 'ftp', value: 'unlimited' },
      'an infinity value' => { domain: 'ftp', value: 'infinity' },
      'a negative value' => { domain: 'ftp', item: 'nice', value: -20 },
      'a numeric string value' => { domain: 'ftp', value: '65536' },
    }

    readable.each do |description, fields|
      context "With #{description}" do
        subject { entry_for(fields) }

        it 'survives being written and read again' do
          parsed = round_trip(subject)

          expect(parsed.index(subject)).to_not be_nil
          expect(parsed.at(0).value).to eq(subject.value)
        end
      end
    end
  end

  context 'With a path that is not a plain filename' do
    # A newline in a filename is legal on Linux, where the only bytes a
    # name cannot carry are '/' and NUL, and pam_limits finds the files it
    # reads by globbing LIMITS_FILE_DIR "/*.conf". A glob '*' matches a
    # newline like any other character, so such a file is read exactly like
    # its better behaved neighbours and the cookbook has no reason to
    # refuse to manage it.
    #
    # What the cookbook does have to do is keep the name inside the header
    # comment it writes. Limits::File#to_s opens the file with
    # "# #{@path}", so today a newline ends that comment and stands the
    # rest of the name up as a line in its own right:
    #
    #   # /etc/security/limits.d/x.conf
    #   evil hard nofile 1
    #   #
    #   # This file is managed by Chef
    #
    # The line reads back as a limit nobody declared. Anything that can
    # influence the path of a managed file, an attribute, a node name, a
    # search result, can therefore add a limit of its own choosing.
    context 'With a newline that smuggles in a limit' do
      let(:path) { "/etc/security/limits.d/x.conf\nevil hard nofile 1" }

      it 'writes back only the limits that were added' do
        parsed = round_trip(Limits::Entry.new('ok', 'hard', 'nofile', 10))

        expect(parsed.map(&:id)).to eq(
          [{ domain: 'ok', type: 'hard', item: 'nofile' }]
        )
      end

      it 'leaves every line of the header commented' do
        header = Limits::File.new(path).to_s.lines.take_while do |line|
          !line.strip.empty?
        end

        expect(header).to all(start_with('#'))
      end
    end

    context 'With a space' do
      # The other half of the same point. A space in a path never leaves
      # the comment, so it is not a problem to be solved and the file has
      # to keep being managed exactly as it is now.
      let(:path) { '/etc/security/limits.d/with space.conf' }

      it 'writes back only the limits that were added' do
        parsed = round_trip(Limits::Entry.new('ok', 'hard', 'nofile', 10))

        expect(parsed.map(&:id)).to eq(
          [{ domain: 'ok', type: 'hard', item: 'nofile' }]
        )
      end
    end
  end

  context 'With a comment' do
    # Comments are written behind a '#', so they cannot break the line the
    # way a bad domain does. They round trip whatever they contain, and
    # this pins that.
    it 'survives a comment that looks like a limit' do
      entry = Limits::Entry.new('ftp', 'hard', 'nofile', 1024, 'evil hard nofile 1')
      parsed = round_trip(entry)

      expect(parsed.index(entry)).to_not be_nil
      expect(parsed.count).to eq(1)
      expect(parsed.at(0).comment).to eq('evil hard nofile 1')
    end
  end
end
