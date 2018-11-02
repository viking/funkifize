require 'test_helper'

class TestParams < Minitest::Test
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

    Funkifize::CLI.start(%w{params create --quiet widget create})

    assert_file_contains "lib/frobnitz.rb",
      %r{# params\s+autoload :WidgetParams, "frobnitz/params/widget_params"}m

    assert_file_contains "lib/frobnitz/params/widget_params.rb",
      %r{module Frobnitz\s+module WidgetParams\s+autoload :Create, "frobnitz/params/widget_params/create"}m

    assert_file_contains "lib/frobnitz/params/widget_params/create.rb",
      %r{module Frobnitz\s+module WidgetParams\s+class Create\b}
  end

  def test_create_dirty
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{params create --quiet --app-constant=FrObNiTz widget create})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :WidgetParams, "frobnitz/params/widget_params"}m
  end
end
