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

  context 'With fields the parser cannot read back' do
    # Each of these writes a line that Limits::REGEX does not match, so the
    # entry is silently dropped on the next read. For example
    #
    #   Limits::Entry.new('foo bar', 'hard', 'nofile', 10).format
    #   # => "foo bar    hard    nofile    10"
    #   Limits::REGEX.match(that) # => nil
    #
    # The domain cases are the ones a user hits by accident, by naming a
    # group with a space in it. The '#' cases are the ones that turn a
    # limit into a comment.
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
