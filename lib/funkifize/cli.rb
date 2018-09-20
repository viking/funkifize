module Funkifize
  class CLI < Thor
    desc "app SUBCOMMAND ...ARGS", "Manage applications"
    subcommand "app", App
  end
end
