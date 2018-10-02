require 'test_helper'

class TestCreateApp < Minitest::Test
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
end
