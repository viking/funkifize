require 'test_helper'

class TestEntity < Minitest::Test
  include TestHelpers

  def setup
    @tmpdir = Dir.mktmpdir
    @pwd = Dir.pwd
    Dir.chdir(@tmpdir)

    Funkifize::CLI.start(%w{app create --quiet frobnitz})
    Dir.chdir("frobnitz")
  end

  def teardown
    Dir.chdir(@pwd)
  end

  def test_create
    Funkifize::CLI.start(%w{entity create --quiet widget})
    assert File.exist?("lib/frobnitz/entities/widget.rb")

    assert_file_contains "lib/frobnitz.rb", /autoload :Widget/

    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*?\n)*?\s+injector\.register_service\('Widget', Widget\)\n/m
  end

  def test_create_with_dirty_app
    gsub_file "lib/frobnitz.rb", /^\s+# entities$/, ""

    Funkifize::CLI.start(%w{entity create --quiet widget})

    assert_file_contains "lib/frobnitz.rb", /autoload :Widget/
  end
end
