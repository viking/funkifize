module Funkifize
  module Commands
    class Validator < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then Validator::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] validator <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        include Funkifize::Helpers

        attr_reader :resource_name, :action_name, :validators_module_name,
          :validators_module_constant, :validator_name, :validator_constant

        def run(argv = [])
          @resource_name = argv.shift
          @action_name = argv.shift

          if @resource_name.nil? || @action_name.nil?
            $stderr.puts "Usage: funkifize [opts] validator create <name>"
            return
          end

          setup
          create_validators_module_file
          setup_autoload_for_validators_module
          create_validator_file
          setup_autoload_for_validator_class
        end

        def setup
          self.destination_root = options[:root] if options[:root]
          @validators_module_name = "#{resource_name}_validators"
          @validators_module_constant = make_constant_name(@validators_module_name)
          @validator_name = action_name
          @validator_constant = make_constant_name(@validator_name)
        end

        def create_validators_module_file
          empty_directory(File.join("lib", app_name, "validators"))
          template("validators_module.rb", File.join("lib", app_name, "validators", "#{validators_module_name}.rb"))
        end

        def setup_autoload_for_validators_module
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# validator" or just
          # before the end of the main app module
          pattern = /^([ \t]*)module #{app_constant}.*?\n(?:\s*# validators.*?\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\\1  autoload :#{validators_module_constant}, "#{app_name}/validators/#{validators_module_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def create_validator_file
          empty_directory(File.join("lib", app_name, "validators", validators_module_name))
          template("validator.rb", File.join("lib", app_name, "validators", validators_module_name, "#{validator_name}.rb"))
        end

        def setup_autoload_for_validator_class
          target = File.join("lib", app_name, "validators", "#{validators_module_name}.rb")
          pattern = /^(\s*)module #{validators_module_constant}\n/m
          rplmnt = %{\\1  autoload :#{validator_constant}, "#{app_name}/validators/#{validators_module_name}/#{validator_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end
      end
    end
  end
end
