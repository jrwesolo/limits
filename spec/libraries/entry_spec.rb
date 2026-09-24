require_relative '../spec_helper'

describe Limits::Entry do
  context 'With all fields set' do
    subject { Limits::Entry.new('*', 'hard', 'nproc', '10', 'hello world') }

    it '#columns' do
      expect(subject.columns).to eq([1, 4, 5, 2])
    end

    it '#id' do
      expect(subject.id).to eq(domain: '*', type: 'hard', item: 'nproc')
    end

    it '#to_s' do
      expect(subject.to_s).to eq('* hard nproc 10 (hello world)')
    end

    it '#format' do
      expect(subject.format).to eq("# hello world\n*    hard    nproc    10")
    end

    it '#format (columns set)' do
      expect(subject.format([3, 2, 8, 0])).to eq("# hello world\n*      hard    nproc       10")
    end

    it '#format (spacing set)' do
      expect(subject.format(nil, 2)).to eq("# hello world\n*  hard  nproc  10")
    end
  end

  context 'With no comment' do
    subject { Limits::Entry.new('*', 'hard', 'nproc', '10') }

    it '#to_s' do
      expect(subject.to_s).to eq('* hard nproc 10')
    end

    it '#format' do
      expect(subject.format).to eq('*    hard    nproc    10')
    end
  end

  context 'With multi-line comment' do
    subject { Limits::Entry.new('*', 'hard', 'nproc', '10', "hello\nworld") }

    it '#to_s' do
      expect(subject.to_s).to eq('* hard nproc 10 (hello\nworld)')
    end

    it '#format' do
      expect(subject.format).to eq("# hello\n# world\n*    hard    nproc    10")
    end
  end

  # An entry stores the comment it is handed. The '#' a file puts in front
  # of a comment is taken off by Limits::File as it reads, so a '#' that
  # reaches an entry belongs to the comment's own text and has to be kept.
  context 'With a comment whose own text starts with a hash' do
    subject { Limits::Entry.new('*', 'hard', 'nproc', '10', '# warning') }

    it 'keeps the comment exactly as given' do
      expect(subject.comment).to eq('# warning')
    end

    it '#format writes it behind a hash of its own' do
      expect(subject.format).to eq("# # warning\n*    hard    nproc    10")
    end
  end

  context 'With no value or comment' do
    subject { Limits::Entry.new('*', 'hard', 'nproc') }

    it '#columns' do
      expect(subject.columns).to eq([1, 4, 5, 0])
    end

    it '#to_s' do
      expect(subject.to_s).to eq('* hard nproc')
    end

    it '#format' do
      expect(subject.format).to eq('*    hard    nproc')
    end
  end

  describe '#<=>' do
    # Sort order decides how a rewritten file reads, and until now it was
    # only observable through the line ordering inside Limits::File#to_s,
    # which meant the file specs were testing comparison by accident.
    #
    # The order is: entries carrying a comment first, so they keep the
    # blank lines around them at the top of the file, then domain, type and
    # item. Value is not part of it, matching Entry#id.
    def entry(domain, type = 'hard', item = 'nofile', comment = nil)
      Limits::Entry.new(domain, type, item, 10, comment)
    end

    it 'sorts a commented entry before an uncommented one' do
      expect(entry('b', 'hard', 'nofile', 'note')).to be < entry('a')
    end

    it 'sorts by domain when neither has a comment' do
      expect(entry('a')).to be < entry('b')
    end

    it 'sorts by domain when both have comments' do
      # Only the presence of a comment is part of the order, never its
      # content, so two commented entries fall through to the domain.
      expect(entry('a', 'hard', 'nofile', 'zzz'))
        .to be < entry('b', 'hard', 'nofile', 'aaa')
    end

    it 'sorts by type when the domain matches' do
      expect(entry('a', '-')).to be < entry('a', 'hard')
    end

    it 'sorts by item when the domain and type match' do
      expect(entry('a', 'hard', 'core')).to be < entry('a', 'hard', 'nofile')
    end

    it 'treats entries with the same identity as equal' do
      a = entry('a')
      same = entry('a')

      expect(a <=> same).to eq(0)
    end

    it 'ignores the value, which is not part of the identity' do
      a = Limits::Entry.new('a', 'hard', 'nofile', 10)
      b = Limits::Entry.new('a', 'hard', 'nofile', 20)

      expect(a <=> b).to eq(0)
    end

    it 'treats fields it cannot compare as equal rather than raising' do
      # Ruby cannot order an Integer against a String, and an entry takes
      # whichever it is handed: the resources always pass strings, but a
      # caller writing a uid domain as a number does not have to. This is
      # the defensive branch rather than an everyday one.
      numeric = Limits::Entry.new(1000, 'hard', 'nofile', 10)
      named = Limits::Entry.new('ftp', 'hard', 'nofile', 10)

      expect(numeric <=> named).to eq(0)
    end

    it 'orders a list of entries' do
      entries = [
        entry('b'),
        entry('a', 'hard', 'core'),
        entry('c', 'hard', 'nofile', 'note'),
        entry('a'),
      ]

      expect(entries.sort.map(&:domain)).to eq(%w(c a a b))
    end
  end
end
