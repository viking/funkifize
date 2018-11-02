require 'test_helper'

class TestRouter < Minitest::Test
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

    Funkifize::CLI.start(%w{router create --quiet widget})
    assert File.exist?("lib/frobnitz/routers/widget_router.rb")

    assert_file_contains "lib/frobnitz.rb",
      %r{# routers\s+autoload :WidgetRouter, "frobnitz/routers/widget_router"}m

    assert_file_contains "lib/frobnitz/builder.rb",
      /def bootstrap\n((?!\s*end\b).*\n)*?\s+injector\.register_service\('WidgetRouter', WidgetRouter\)\n/m

    assert_file_contains "lib/frobnitz/application.rb",
      /def self\.dependencies\n\s+%w{WidgetRouter}/m
    assert_file_contains "lib/frobnitz/application.rb",
      /def initialize\(widget_router\)/
    assert_file_contains "lib/frobnitz/application.rb",
      "{ path: %r{^/widgets(?=/)?}, router: widget_router }"
  end

  def test_create_with_dirty_app
    setup_app

    gsub_file "lib/frobnitz.rb", /^\s+# routers$/, ""

    gsub_file "lib/frobnitz/application.rb",
      /def self\.dependencies\s+%w\{/, '\0Blah'
    gsub_file "lib/frobnitz/application.rb",
      /def initialize/, '\0(blah)'
    gsub_file "lib/frobnitz/application.rb",
      /^(\s+)@routes = \[\n\1/, "\\0  { path: /omg/ },\n\\1"

    Funkifize::CLI.start(%w{router create --quiet widget})

    assert_file_contains "lib/frobnitz.rb", /autoload :WidgetRouter/
    assert_file_contains "lib/frobnitz/application.rb",
      /def self\.dependencies\s+%w\{Blah WidgetRouter\}/
    assert_file_contains "lib/frobnitz/application.rb",
      /def initialize\(blah, widget_router\)/
    assert_file_contains "lib/frobnitz/application.rb",
      "{ path: %r{^/widgets(?=/)?}, router: widget_router }"
  end

  def test_create_with_custom_app_constant
    setup_app(%w{--app-constant=FrObNiTz})

    Funkifize::CLI.start(%w{router create --quiet --app-constant=FrObNiTz widget})

    assert_file_contains "lib/frobnitz.rb",
      %r{module FrObNiTz.+autoload :WidgetRouter, "frobnitz/routers/widget_router"}m
  end
end
