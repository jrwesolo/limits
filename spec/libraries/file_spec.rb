require_relative '../spec_helper'

describe Limits::File do
  let(:file_stub) do
    <<~'EOF'
      # this is a comment for user4
      user4 - nproc 40
      user2 - nproc 20 # inline comment
      # this is a comment for:
      # user3
      user3 - nproc 30
      user1 - nofile 1024

      # comment without limit

      invalid limit
      user5 - cpu 50
    EOF
  end

  context 'Using new file' do
    subject { Limits::File.new('limits.conf') }

    before do
      allow(::File).to receive(:exist?).with('limits.conf').and_return(false)
      allow(::File).to receive(:read).with('limits.conf').and_return(file_stub)
    end

    context 'With no changes' do
      it '#index' do
        expect(subject.index(Limits::Entry.new('apple', 'soft', 'nproc'))).to be_nil
      end

      it '#at' do
        expect(subject.at(0)).to be_nil
      end

      it '#columns' do
        expect(subject.columns).to be_empty
      end

      it '#to_s' do
        expect(subject.to_s).to eq(<<~'EOF')
          # limits.conf
          #
          # This file is managed by Chef
          # Local changes may be lost!

          # End of file (0 limits)
        EOF
      end
    end

    context 'With one limit added' do
      before do
        subject.add(Limits::Entry.new('apple', 'soft', 'nproc', '10'))
      end

      it '#index' do
        expect(subject.index(Limits::Entry.new('apple', 'soft', 'nproc'))).to eq(0)
      end

      it '#at' do
        expect(subject.at(0)).to_not be_nil
        expect(subject.at(1)).to be_nil
      end

      it '#columns' do
        expect(subject.columns).to eq([5, 4, 5, 2])
      end

      it '#to_s' do
        expect(subject.to_s).to eq(<<~'EOF')
          # limits.conf
          #
          # This file is managed by Chef
          # Local changes may be lost!

          apple    soft    nproc    10

          # End of file (1 limit)
        EOF
      end

      # The only path by which anything in this cookbook reaches disk
      # outside of Chef's own file resource. Both limit actions call it, so
      # it is worth pinning that it writes the rendered file to the path it
      # was built with and nowhere else.
      it '#write!' do
        expect(::File).to receive(:write).with('limits.conf', subject)

        subject.write!
      end
    end

    context 'With changes' do
      before do
        subject.add(Limits::Entry.new('apple', 'soft', 'nproc', '10'))
        subject.add(Limits::Entry.new('orange', 'hard', 'nproc', '100', 'comment'))
      end

      it '#index' do
        expect(subject.index(Limits::Entry.new('apple', 'soft', 'nproc'))).to_not be_nil
        expect(subject.index(Limits::Entry.new('pear', 'soft', 'nproc'))).to be_nil
      end

      it '#at' do
        expect(subject.at(0)).to_not be_nil
        expect(subject.at(100)).to be_nil
      end

      it '#columns' do
        expect(subject.columns).to eq([6, 4, 5, 3])
      end

      it '#to_s' do
        expect(subject.to_s).to eq(<<~'EOF')
          # limits.conf
          #
          # This file is managed by Chef
          # Local changes may be lost!

          # comment
          orange    hard    nproc    100

          apple     soft    nproc    10

          # End of file (2 limits)
        EOF
      end
    end
  end

  context 'Using an existing but empty file' do
    # What a limits.d file looks like after someone empties it by hand, and
    # what every file looks like the first time limits_file manages one
    # that was created by something else.
    subject { Limits::File.new('limits.conf') }

    before do
      allow(::File).to receive(:exist?).with('limits.conf').and_return(true)
      allow(::File).to receive(:read).with('limits.conf').and_return('')
    end

    it '#count' do
      expect(subject.count).to eq(0)
    end

    it '#columns' do
      expect(subject.columns).to be_empty
    end

    it '#to_s' do
      expect(subject.to_s).to eq(<<~'EOF')
        # limits.conf
        #
        # This file is managed by Chef
        # Local changes may be lost!

        # End of file (0 limits)
      EOF
    end
  end

  context 'Using existing file' do
    subject { Limits::File.new('limits.conf') }

    before do
      allow(::File).to receive(:exist?).with('limits.conf').and_return(true)
      allow(::File).to receive(:read).with('limits.conf').and_return(file_stub)
    end

    context 'With no changes' do
      it '#index' do
        expect(subject.index(Limits::Entry.new('user4', '-', 'nproc'))).to_not be_nil
        expect(subject.index(Limits::Entry.new('does', 'not', 'exist'))).to be_nil
      end

      it '#at' do
        expect(subject.at(0)).to_not be_nil
        expect(subject.at(100)).to be_nil
      end

      it '#columns' do
        expect(subject.columns).to eq([5, 1, 6, 4])
      end

      it '#to_s' do
        expect(subject.to_s).to eq(<<~'EOF')
          # limits.conf
          #
          # This file is managed by Chef
          # Local changes may be lost!

          # this is a comment for:
          # user3
          user3    -    nproc     30

          # this is a comment for user4
          user4    -    nproc     40

          user1    -    nofile    1024
          user2    -    nproc     20
          user5    -    cpu       50

          # End of file (5 limits)
        EOF
      end
    end

    context 'With a delete that matches nothing' do
      # The :delete action of the limit resource reaches this whenever it
      # runs against a limit that is not in the file, which is the ordinary
      # case once the limit has been removed one time.
      it 'leaves the file alone' do
        before_delete = subject.to_s

        subject.delete(Limits::Entry.new('nobody', 'hard', 'nofile'))

        expect(subject.count).to eq(5)
        expect(subject.to_s).to eq(before_delete)
      end
    end

    context 'With changes' do
      before do
        subject.delete(Limits::Entry.new('user4', '-', 'nproc'))
        subject.add(Limits::Entry.new('user3', '-', 'nproc', '40', 'replace comment'))
        subject.add(Limits::Entry.new('user5', '-', 'cpu', '50', 'new comment'))
        subject.add(Limits::Entry.new('user10', 'soft', 'cpu', '40'))
      end

      it '#index' do
        expect(subject.index(Limits::Entry.new('user4', '-', 'nproc'))).to be_nil
        expect(subject.index(Limits::Entry.new('user10', 'soft', 'cpu'))).to_not be_nil
      end

      it '#at' do
        expect(subject.at(0)).to_not be_nil
        expect(subject.at(100)).to be_nil
      end

      it '#columns' do
        expect(subject.columns).to eq([6, 4, 6, 4])
      end

      it '#to_s' do
        expect(subject.to_s).to eq(<<~'EOF')
          # limits.conf
          #
          # This file is managed by Chef
          # Local changes may be lost!

          # replace comment
          user3     -       nproc     40

          # new comment
          user5     -       cpu       50

          user1     -       nofile    1024
          user10    soft    cpu       40
          user2     -       nproc     20

          # End of file (5 limits)
        EOF
      end
    end
  end
end
