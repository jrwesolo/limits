require 'spec_helper'

context 'Alice' do

  describe 'Hard limit for nofiles' do
    subject { command("su - alice -c 'ulimit -Hn'") }
    it 'should eq 500' do
      expect(subject.stdout).to eq("500\n")
    end
  end

  describe 'Soft limit for nofiles' do
    subject { command("su - alice -c 'ulimit -Sn'") }
    it 'should eq 250' do
      expect(subject.stdout).to eq("250\n")
    end
  end

end

context 'Bob' do

  describe 'Hard limit for nofiles' do
    subject { command("su - bob -c 'ulimit -Hn'") }
    it 'should eq 12345' do
      expect(subject.stdout).to eq("12345\n")
    end
  end

  describe 'Soft limit for nofiles' do
    subject { command("su - bob -c 'ulimit -Sn'") }
    it 'should eq 5678' do
      expect(subject.stdout).to eq("5678\n")
    end
  end

end
