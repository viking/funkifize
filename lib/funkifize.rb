require "optparse"
require "fileutils"
require "erb"
require "thor"
require "active_support/inflector"

module Funkifize
  autoload :VERSION, "funkifize/version"
  autoload :CLI, "funkifize/cli"
  autoload :Command, "funkifize/command"
  autoload :Helpers, "funkifize/helpers"
  autoload :Commands, "funkifize/commands"
end
