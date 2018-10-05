module Funkifize
  class CLI < Thor
    class_option :root, :type => :string

    desc "app SUBCOMMAND ...ARGS", "Manage applications"
    subcommand "app", App

    desc "router SUBCOMMAND ...ARGS", "Manage routers"
    subcommand "router", Router

    desc "controller SUBCOMMAND ...ARGS", "Manage controllers"
    subcommand "controller", Controller

    desc "repository SUBCOMMAND ...ARGS", "Manage repositories"
    subcommand "repository", Repository
  end
end
