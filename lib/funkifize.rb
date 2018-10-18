require "thor"
require "active_support/inflector"

module Funkifize
  autoload :VERSION, "funkifize/version"
  autoload :CLI, "funkifize/cli"
  autoload :Helpers, "funkifize/helpers"
  autoload :Actions, "funkifize/actions"
  autoload :Commands, "funkifize/commands"
end
