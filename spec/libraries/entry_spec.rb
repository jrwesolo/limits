require 'spec_helper'

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
end
