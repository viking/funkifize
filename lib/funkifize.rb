require "thor"
require "active_support/inflector"

module Funkifize
  autoload :VERSION, "funkifize/version"
  autoload :CLI, "funkifize/cli"
  autoload :App, "funkifize/app"
  autoload :Router, "funkifize/router"
  autoload :Controller, "funkifize/controller"
  autoload :Repository, "funkifize/repository"
  autoload :Helpers, "funkifize/helpers"
  autoload :Actions, "funkifize/actions"
end
