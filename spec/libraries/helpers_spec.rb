require 'spec_helper'

describe Limits::Helpers do
  describe '.normalize_value' do
    values = {
      'One' => 'One',
      '1' => 1,
      1 => 1,
      '1.0' => '1.0',
      '+1' => '+1',
      '-1' => -1,
      1.0 => 1.0,
      nil => nil,
    }

    values.each do |value, expected|
      it value.inspect do
        normalized = subject.normalize_value(value)
        expect(normalized).to eq(expected)
      end
    end
  end

  describe '.normalize_comment' do
    comments = {
      'Hello' => 'Hello',
      'Hello ' => 'Hello ',
      "Hello\n" => "Hello\n",
      "Hello\nWorld" => "Hello\nWorld",
      "Hello\nWorld\n" => "Hello\nWorld\n",
      "Hello \nWorld\n" => "Hello \nWorld\n",
      "Hello\n\nWorld\n\n" => "Hello\n\nWorld\n\n",
      '#Hello' => 'Hello',
      '# Hello' => 'Hello',
      '#  Hello' => ' Hello',
      '#   Hello' => '  Hello',
      '# # Hello' => '# Hello',
      '## Hello' => '# Hello',
      nil => nil,
    }

    comments.each do |comment, expected|
      it comment.inspect do
        normalized = subject.normalize_comment(comment)
        expect(normalized).to eq(expected)
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
end
