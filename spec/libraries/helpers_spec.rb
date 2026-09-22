require 'spec_helper'

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
