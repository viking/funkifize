module Funkifize
  module Commands
    class Params < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then Params::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] params <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        include Funkifize::Helpers
        attr_reader :resource_name, :action_name, :params_module_name,
          :params_module_constant, :params_name, :params_constant

        def run(argv = [])
          @resource_name = argv.shift
          @action_name = argv.shift

          if @resource_name.nil? || @action_name.nil?
            $stderr.puts "Usage: funkifize [opts] params create <resource> <action>"
            return
          end

          setup
          create_params_module_file
          setup_autoload_for_params_module
          create_params_file
          setup_autoload_for_params_class
        end

        def setup
          self.destination_root = options[:root] if options[:root]
          @params_module_name = "#{resource_name}_params"
          @params_module_constant = make_constant_name(@params_module_name)
          @params_name = action_name
          @params_constant = make_constant_name(@params_name)
        end

        def create_params_module_file
          empty_directory(File.join("lib", app_name, "params"))
          template("params_module.rb", File.join("lib", app_name, "params", "#{params_module_name}.rb"))
        end

        def setup_autoload_for_params_module
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# params" or just
          # before the end of the main app module
          pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# params.*?\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\\1  autoload :#{params_module_constant}, "#{app_name}/params/#{params_module_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def create_params_file
          empty_directory(File.join("lib", app_name, "params", params_module_name))
          template("params.rb", File.join("lib", app_name, "params", params_module_name, "#{params_name}.rb"))
        end

        def setup_autoload_for_params_class
          target = File.join("lib", app_name, "params", "#{params_module_name}.rb")
          pattern = /^(\s*)module #{params_module_constant}\n/m
          rplmnt = %{\\1  autoload :#{params_constant}, "#{app_name}/params/#{params_module_name}/#{params_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end
      end
    end
  end
end
