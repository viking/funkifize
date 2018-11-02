require 'test_helper'

class TestUsecase < Minitest::Test
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

    Funkifize::CLI.start(%w{usecase create --quiet widget create})

    assert_file_contains "lib/frobnitz.rb",
      %r{# actions\s+autoload :Widgets, "frobnitz/actions/widgets"}m

    assert_file_contains "lib/frobnitz/actions/widgets.rb",
      %r{module Frobnitz\s+module Widgets\s+autoload :Create, "frobnitz/actions/widgets/create"}m

    assert_file_contains "lib/frobnitz/actions/widgets/create.rb",
      %r{module Frobnitz\s+module Widgets\s+class Create\b}

    assert_file_contains "lib/frobnitz/controllers/widget_controller.rb",
      %r{def initialize\(create, create_params\)\s+@create = create\s+@create_params = create_params}

    assert_file_contains "lib/frobnitz/controllers/widget_controller.rb",
      %r{def self\.dependencies\s+%w\{Widgets::Create WidgetParams::Create\}}

    assert_file_contains "lib/frobnitz/controllers/widget_controller.rb",
      %r{
        \n\n\ +
        def\ create\(req,\ res\)\s+
          data\ =\ JSON.parse\(req\.body\.read\)\s+
          params\ =\ @create_params\.process\(data\)\s+
          @create\.run\(params\)\s+
        end\s+end
      }mx
  end

  def test_create_dirty
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})
    Funkifize::CLI.start(%w{controller create --quiet widget})

    Funkifize::CLI.start(%w{usecase create --quiet --app-constant=FrObNiTz widget create})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :Widgets, "frobnitz/actions/widgets"}m
  end
end
