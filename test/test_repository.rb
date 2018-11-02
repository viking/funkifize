require 'test_helper'

class TestRepository < Minitest::Test
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

    Funkifize::CLI.start(%w{repository create --quiet widget})
    assert File.exist?("lib/frobnitz/repositories/widget_repository.rb")

    assert_file_contains "lib/frobnitz.rb",
      %r{# repositories\s+autoload :WidgetRepository, "frobnitz/repositories/widget_repository"}m

    assert File.exist?("db/migrate/001_create_widgets.rb")
    assert_file_contains "db/migrate/001_create_widgets.rb", "create_table(:widgets)"

    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*?\n)*?\s+injector\.register_service\('WidgetRepository', WidgetRepository\)\n/m
  end

  def test_create_with_dirty_app
    setup_app

    gsub_file "lib/frobnitz.rb", /^\s+# repositories$/, ""
    touch_file "db/migrate/001_foo.rb"

    Funkifize::CLI.start(%w{repository create --quiet widget})

    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetRepository/

    assert File.exist?("db/migrate/002_create_widgets.rb")
    assert_file_contains "db/migrate/002_create_widgets.rb", "create_table(:widgets)"
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{repository create --quiet --app-constant=FrObNiTz widget})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :WidgetRepository, "frobnitz/repositories/widget_repository"}m
  end
end
