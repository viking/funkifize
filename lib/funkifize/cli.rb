module Funkifize
  class CLI
    def self.start(argv = ARGV)
      options = {}
      OptionParser.new do |opts|
        opts.on("--root=ROOT", "Root directory of application") do |root|
          options[:root] = root
        end

        opts.on("--app-name=APP_NAME", "Name of application") do |app_name|
          options[:app_name] = app_name
        end

        opts.on("--app-constant=APP_CONSTANT", "Primary module name of application") do |app_constant|
          options[:app_constant] = app_constant
        end

        opts.on("--quiet", "Don't print status messages") do |quiet|
          options[:quiet] = quiet
        end
      end.parse!(argv)

      command_name = argv.shift
      klass =
        case command_name
        when "app" then Commands::App
        when "router" then Commands::Router
        when "controller" then Commands::Controller
        when "repository" then Commands::Repository
        when "entity" then Commands::Entity
        when "params" then Commands::Params
        when "validator" then Commands::Validator
        when "action" then Commands::Action
        else
          nil
        end

      if klass.nil?
        $stderr.puts "Usage: funkifize [opts] <command> <args>"
        $stderr.puts "Commands: app, router, controller, repository, entity, params, validator, action"
      else
        command = klass.new(options)
        command.run(argv)
      end
    end
  end
end
