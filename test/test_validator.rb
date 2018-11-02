require 'test_helper'

class TestValidator < Minitest::Test
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

    Funkifize::CLI.start(%w{validator create --quiet widget create})

    assert_file_contains "lib/frobnitz.rb",
      %r{# validators\s+autoload :WidgetValidators, "frobnitz/validators/widget_validators"}m

    assert_file_contains "lib/frobnitz/validators/widget_validators.rb",
      %r{module Frobnitz\s+module WidgetValidators\s+autoload :Create, "frobnitz/validators/widget_validators/create"}m

    assert_file_contains "lib/frobnitz/validators/widget_validators/create.rb",
      %r{module Frobnitz\s+module WidgetValidators\s+class Create\b}
  end

  def test_create_dirty
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{validator create --quiet --app-constant=FrObNiTz widget create})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :WidgetValidators, "frobnitz/validators/widget_validators"}m
  end
end
