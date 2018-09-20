module Funkifize
  class CLI < Thor
    class_option :chdir, :type => :string

    desc "app SUBCOMMAND ...ARGS", "Manage applications"
    subcommand "app", App

    desc "router SUBCOMMAND ...ARGS", "Manage routers"
    subcommand "router", Router
  end
end
