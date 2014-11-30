require 'spec_helper'

describe 'Limits of Alice' do

  describe command("su - alice -c 'ulimit -Hn'") do
    its(:stdout) { is_expected.to eq("500\n") }
  end

  describe command("su - alice -c 'ulimit -Sn'") do
    its(:stdout) { is_expected.to eq("250\n") }
  end

end

describe 'Limits of Bob' do

  describe command("su - bob -c 'ulimit -Hn'") do
    its(:stdout) { is_expected.to eq("12345\n") }
  end

  describe command("su - bob -c 'ulimit -Sn'") do
    its(:stdout) { is_expected.to eq("5678\n") }
  end

end
