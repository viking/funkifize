module Funkifize
  module Commands
    class Controller < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then Controller::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] controller <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        include Funkifize::Helpers
        attr_reader :resource_name, :resource_constant, :controller_name, :controller_constant

        def run(argv = [])
          @resource_name = argv.shift

          if @resource_name.nil?
            $stderr.puts "Usage: funkifize [opts] controller create <name>"
            return
          end

          setup
          create_controller_file
          add_autoload_instruction
          setup_injector
        end

        def setup
          self.destination_root = options[:root] if options[:root]
          @resource_constant = make_constant_name(resource_name)
          @controller_name = "#{resource_name}_controller"
          @controller_constant = make_constant_name(@controller_name)
        end

        def create_controller_file
          empty_directory(File.join("lib", app_name, "controllers"))
          template("controller.rb", File.join("lib", app_name, "controllers", "#{controller_name}.rb"))
        end

        def add_autoload_instruction
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# controllers" or just
          # before the end of the main app module
          pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# controllers.*?\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\\1  autoload :#{controller_constant}, "#{app_name}/controllers/#{controller_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def setup_injector
          target = File.join("lib", app_name, "builder.rb")

          # put line # just before the end of the bootstrap function
          pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
          rplmnt = %{\\1  injector.register_service('#{controller_constant}', #{controller_constant})\n}
          inject_into_file(target, rplmnt, pattern)
        end
      end
    end
  end
end
