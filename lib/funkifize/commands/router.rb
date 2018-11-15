module Funkifize
  module Commands
    class Router < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then Router::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] router <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        include Funkifize::Helpers
        attr_reader :resource_name, :resource_constant, :router_name, :router_constant

        def run(argv = [])
          @resource_name = argv.shift

          if @resource_name.nil?
            $stderr.puts "Usage: funkifize [opts] router create <name>"
            return
          end

          setup
          create_router_file
          add_autoload_instruction
          setup_injector
          add_application_dependency
          add_default_route
        end

        def setup
          self.destination_root = options[:root] if options[:root]
          @resource_constant = make_constant_name(resource_name)
          @router_name = "#{resource_name}_router"
          @router_constant = make_constant_name(@router_name)
        end

        def create_router_file
          empty_directory(File.join("lib", app_name, "routers"))
          template("router.rb", File.join("lib", app_name, "routers", "#{router_name}.rb"))
        end

        def add_autoload_instruction
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# routers" or just
          # before the end of the main app module
          pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# routers.*?\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\\1  autoload :#{router_constant}, "#{app_name}/routers/#{router_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def setup_injector
          target = File.join("lib", app_name, "builder.rb")

          # put line # just before the end of the bootstrap function
          pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
          rplmnt = %{\\1  injector.register_service('#{router_constant}', #{router_constant})\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def add_application_dependency
          target = File.join("lib", app_name, "application.rb")
          add_class_dependency(target, "Application", router_name, router_constant, instance_vars: false)
        end

        def add_default_route
          target = File.join("lib", app_name, "application.rb")

          # put line # just before the end of the bootstrap function
          pattern = %r{
            ^([ \t]+)def\ initialize.*?\n
            \1\ \ @routes\ =\ \[\n
            (\1\ \ \ \ .*?\n)*
            (?=\1\ \ \])
          }xm
          rplmnt = "\\1    { path: %r{^/#{pluralize(resource_name)}(?=/)?}, router: #{router_name} },\n"
          inject_into_file(target, rplmnt, pattern)
        end
      end
    end
  end
end
