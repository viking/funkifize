module Funkifize
  module Commands
    class Usecase < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then Usecase::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] usecase <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        include Funkifize::Helpers
        attr_reader :resource_name, :resource_constant, :actions_module_name,
          :actions_module_constant, :action_name, :action_constant

        def run(argv = [])
          @resource_name = argv.shift
          @action_name = argv.shift

          if @resource_name.nil? || @action_name.nil?
            $stderr.puts "Usage: funkifize [opts] app create <name>"
            return
          end

          setup
          create_actions_module_file
          setup_autoload_for_actions_module
          create_action_file
          setup_autoload_for_action_class
          add_dependencies_to_controller
          add_controller_action_method
        end

        def setup
          self.destination_root = options[:root] if options[:root]
          @resource_constant = make_constant_name(resource_name)
          @actions_module_name = pluralize(resource_name)
          @actions_module_constant = make_constant_name(@actions_module_name)
          @action_constant = make_constant_name(action_name)
        end

        def create_actions_module_file
          empty_directory(File.join("lib", app_name, "actions"))
          template("actions_module.rb", File.join("lib", app_name, "actions", "#{actions_module_name}.rb"))
        end

        def setup_autoload_for_actions_module
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# actions" or just
          # before the end of the main app module
          pattern = /^([ \t]*)module #{app_constant}.*?\n(?:\s*# actions.*?\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\\1  autoload :#{actions_module_constant}, "#{app_name}/actions/#{actions_module_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def create_action_file
          empty_directory(File.join("lib", app_name, "actions", actions_module_name))
          template("action.rb", File.join("lib", app_name, "actions", actions_module_name, "#{action_name}.rb"))
        end

        def setup_autoload_for_action_class
          target = File.join("lib", app_name, "actions", "#{actions_module_name}.rb")
          pattern = /^(\s*)module #{actions_module_constant}\n/m
          rplmnt = %{\\1  autoload :#{action_constant}, "#{app_name}/actions/#{actions_module_name}/#{action_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def add_dependencies_to_controller
          target = File.join("lib", app_name, "controllers", "#{resource_name}_controller.rb")
          add_class_dependency(target, "#{resource_constant}Controller", action_name, "#{actions_module_constant}::#{action_constant}")
          add_class_dependency(target, "#{resource_constant}Controller", "#{action_name}_params", "#{resource_constant}Params::#{action_constant}")
        end

        def add_controller_action_method
          target = File.join("lib", app_name, "controllers", "#{resource_name}_controller.rb")
          pattern = /^([ \t]*)module #{app_constant}\n\1  class #{resource_constant}Controller.*?\n(?=\1  end\s*)/m
          rplmnt = %{\n    def #{action_name}(req, res)\n      data = JSON.parse(req.body.read)\n      params = @#{action_name}_params.process(data)\n      @#{action_name}.run(params)\n    end\n}
          inject_into_file(target, rplmnt, pattern)
        end
      end
    end
  end
end
