require 'test_helper'

class TestCreateApp < Minitest::Test
  include TestHelpers

  def setup
    @tmpdir = Dir.mktmpdir
    @pwd = Dir.pwd
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@pwd)
  end

  def test_generate_app
    Funkifize::CLI.start(%w{app create --quiet frobnitz})
    assert File.exist?("frobnitz/lib/frobnitz.rb")
  end

  def test_generate_app_with_custom_constant
    Funkifize::CLI.start(%w{app create --quiet --app-constant=FrObNiTz frobnitz})
    assert_file_contains "frobnitz/lib/frobnitz.rb", "module FrObNiTz"
  end
end
