module Funkifize
  class CLI < Thor
    class_option :root, :type => :string

    desc "app SUBCOMMAND ...ARGS", "Manage applications"
    subcommand "app", Commands::App

    desc "router SUBCOMMAND ...ARGS", "Manage routers"
    subcommand "router", Commands::Router

    desc "controller SUBCOMMAND ...ARGS", "Manage controllers"
    subcommand "controller", Commands::Controller

    desc "repository SUBCOMMAND ...ARGS", "Manage repositories"
    subcommand "repository", Commands::Repository

    desc "entity SUBCOMMAND ...ARGS", "Manage entities"
    subcommand "entity", Commands::Entity

    desc "params SUBCOMMAND ...ARGS", "Manage params"
    subcommand "params", Commands::Params

    desc "validator SUBCOMMAND ...ARGS", "Manage validators"
    subcommand "validator", Commands::Validator

    desc "usecase SUBCOMMAND ...ARGS", "Manage use cases (actions)"
    subcommand "usecase", Commands::Usecase
  end
end
