require 'test_helper'

class TestEntity < Minitest::Test
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

    Funkifize::CLI.start(%w{entity create --quiet widget})
    assert File.exist?("lib/frobnitz/entities/widget.rb")

    assert_file_contains "lib/frobnitz.rb",
      %r{# entities\s+autoload :Widget, "frobnitz/entities/widget"}m

    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*?\n)*?\s+injector\.register_service\('Widget', Widget\)\n/m
  end

  def test_create_with_dirty_app
    setup_app

    gsub_file "lib/frobnitz.rb", /^\s+# entities$/, ""

    Funkifize::CLI.start(%w{entity create --quiet widget})

    assert_file_contains "lib/frobnitz.rb", /autoload :Widget/
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{entity create --quiet --app-constant=FrObNiTz widget})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :Widget, "frobnitz/entities/widget"}m
  end
end
