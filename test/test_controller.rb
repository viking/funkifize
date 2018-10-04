require 'test_helper'

class TestController < Minitest::Test
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
    Funkifize::CLI.start(%w{controller create --quiet widget})
    assert File.exist?("lib/frobnitz/controllers/widget_controller.rb")

    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetController/

    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*?\n)*?\s+injector\.register_service\('WidgetController', WidgetController\)\n/m
  end

  def test_create_with_dirty_app
    gsub_file "lib/frobnitz.rb", /^\s+# controllers$/, ""

    Funkifize::CLI.start(%w{controller create --quiet widget})

    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetController/
  end
end
