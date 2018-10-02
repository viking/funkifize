require 'test_helper'

class TestRouter < Minitest::Test
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
    Funkifize::CLI.start(%w{router create --quiet widget})
    assert File.exist?("lib/frobnitz/routers/widget_router.rb")
    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetRouter/
    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*\n)*?\s+injector\.register_service\('WidgetRouter', WidgetRouter\)\n/m
    assert_file_contains "lib/frobnitz/application.rb",
      /def self\.dependencies\n\s+%w{WidgetRouter }/m
  end

  def test_create_with_dirty_app
    gsub_file "lib/frobnitz.rb", /^\s+# routers$/, ""
    Funkifize::CLI.start(%w{router create --quiet widget})
    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetRouter/
  end
end
