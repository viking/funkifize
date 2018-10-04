$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "funkifize"

require "tmpdir"
require "minitest/autorun"

module TestHelpers
  def assert_file_contains(filename, pattern)
    data = File.read(filename)
    case pattern
    when Regexp
      assert data.match?(pattern), "#{pattern.inspect} was not contained in #{filename}"
    when String
      assert data.include?(pattern)
    else
      raise "pattern is not a regexp or a string"
    end
  end

  def gsub_file(filename, pattern, replacement)
    content = File.binread(filename)
    content.gsub!(pattern, replacement)
    File.open(filename, "wb") { |file| file.write(content) }
  end
end
