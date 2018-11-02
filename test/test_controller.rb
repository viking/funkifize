require 'test_helper'

class TestController < Minitest::Test
  include TestHelpers

  def setup
    @tmpdir = Dir.mktmpdir
    @pwd = Dir.pwd
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@pwd)
  end

  def test_create
    setup_app

    Funkifize::CLI.start(%w{controller create --quiet widget})
    assert File.exist?("lib/frobnitz/controllers/widget_controller.rb")

    assert_file_contains "lib/frobnitz.rb",
      %r{# controllers\s+autoload :WidgetController, "frobnitz/controllers/widget_controller"}m

    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*?\n)*?\s+injector\.register_service\('WidgetController', WidgetController\)\n/m
  end

  def test_create_with_dirty_app
    setup_app

    gsub_file "lib/frobnitz.rb", /^\s+# controllers$/, ""

    Funkifize::CLI.start(%w{controller create --quiet widget})

    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetController/
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{controller create --quiet --app-constant=FrObNiTz widget})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :WidgetController, "frobnitz/controllers/widget_controller"}m
  end

  def test_create_with_auto_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{controller create --quiet widget})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :WidgetController, "frobnitz/controllers/widget_controller"}m
  end
end
