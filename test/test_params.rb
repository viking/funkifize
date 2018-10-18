require 'test_helper'

class TestParams < Minitest::Test
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
end
