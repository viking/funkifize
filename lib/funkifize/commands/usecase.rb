class Funkifize::Commands::Usecase < Thor
  class Create < Thor::Group
    include Thor::Actions
    include Funkifize::Helpers
    attr_reader :resource_constant, :actions_module_name,
      :actions_module_constant, :action_constant

    add_runtime_options!
    argument :resource_name, :desc => "Name of resource to make a action for"
    argument :action_name, :desc => "Name of action to make"

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "templates"))
    end

    def self.printable_commands(*args)
      # don't print this command twice
      []
    end

    def setup
      self.destination_root = options[:root] if options[:root]
      @action_options = { verbose: !options[:quiet] }
      @resource_constant = make_constant_name(resource_name)
      @actions_module_name = pluralize(resource_name)
      @actions_module_constant = make_constant_name(@actions_module_name)
      @action_constant = make_constant_name(action_name)
    end

    def create_actions_module_file
      empty_directory(File.join("lib", app_name, "actions"), @action_options)
      template("actions_module.rb", File.join("lib", app_name, "actions", "#{actions_module_name}.rb"), @action_options)
    end

    def setup_autoload_for_actions_module
      target = File.join("lib", "#{app_name}.rb")

      # put line either after a block starting with "# actions" or just
      # before the end of the main app module
      pattern = /^([ \t]*)module #{app_constant}.*?\n(?:\s*# actions.*?\n(?=\n)|(?=\1end\s*))/m
      rplmnt = %{\\1  autoload :#{actions_module_constant}, "#{app_name}/actions/#{actions_module_name}"\n}
      inject_into_file(target, rplmnt, @action_options.merge(after: pattern))
    end

    def create_action_file
      empty_directory(File.join("lib", app_name, "actions", actions_module_name), @action_options)
      template("action.rb", File.join("lib", app_name, "actions", actions_module_name, "#{action_name}.rb"), @action_options)
    end

    def setup_autoload_for_action_class
      inject_into_module(File.join("lib", app_name, "actions", "#{actions_module_name}.rb"), actions_module_constant, @action_options) do
        %{    autoload :#{action_constant}, "#{app_name}/actions/#{actions_module_name}/#{action_name}"\n}
      end
    end

    def add_dependencies_to_controller
      target = File.join("lib", app_name, "controllers", "#{resource_name}_controller.rb")
      add_class_dependency(target, "#{resource_constant}Controller", action_name, "#{actions_module_constant}::#{action_constant}", @action_options)
      add_class_dependency(target, "#{resource_constant}Controller", "#{action_name}_params", "#{resource_constant}Params::#{action_constant}", @action_options)
    end

    def add_controller_action_method
      target = File.join("lib", app_name, "controllers", "#{resource_name}_controller.rb")
      pattern = /^([ \t]*)module #{app_constant}\n\1  class #{resource_constant}Controller.*?\n(?=\1  end\s*)/m
      rplmnt = %{\n    def #{action_name}(req, res)\n      data = JSON.parse(req.body.read)\n      params = @#{action_name}_params.process(data)\n      @#{action_name}.run(params)\n    end\n}
      inject_into_file(target, rplmnt, @action_options.merge(after: pattern))
    end
  end

  register Funkifize::Commands::Usecase::Create, "create", "create ACTION_NAME", "Create action named ACTION_NAME"
end
