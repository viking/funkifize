class Funkifize::Commands::Params < Thor
  class Create < Thor::Group
    include Thor::Actions
    include Funkifize::Helpers
    attr_reader :params_module_name, :params_module_constant, :params_name,
      :params_constant

    add_runtime_options!
    argument :resource_name, :desc => "Name of resource to make a params class for"
    argument :action_name, :desc => "Name of action to create a params class for"

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "templates"))
    end

    def self.printable_commands(*args)
      # don't print this command twice
      []
    end

    def setup
      self.destination_root = options[:root] if options[:root]
      @params_options = { verbose: !options[:quiet] }
      @params_module_name = "#{resource_name}_params"
      @params_module_constant = make_constant_name(@params_module_name)
      @params_name = action_name
      @params_constant = make_constant_name(@params_name)
    end

    def create_params_module_file
      empty_directory(File.join("lib", app_name, "params"), @params_options)
      template("params_module.rb", File.join("lib", app_name, "params", "#{params_module_name}.rb"), @params_options.merge(skip: true))
    end

    def setup_autoload_for_params_module
      target = File.join("lib", "#{app_name}.rb")

      # put line either after a block starting with "# params" or just
      # before the end of the main app module
      pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# params.*?\n(?=\n)|(?=\1end\s*))/m
      rplmnt = %{\\1  autoload :#{params_module_constant}, "#{app_name}/params/#{params_module_name}"\n}
      inject_into_file(target, rplmnt, @params_options.merge(after: pattern))
    end

    def create_params_file
      empty_directory(File.join("lib", app_name, "params", params_module_name), @params_options)
      template("params.rb", File.join("lib", app_name, "params", params_module_name, "#{params_name}.rb"), @params_options)
    end

    def setup_autoload_for_params_class
      inject_into_module(File.join("lib", app_name, "params", "#{params_module_name}.rb"), params_module_constant, @params_options) do
        %{    autoload :#{params_constant}, "#{app_name}/params/#{params_module_name}/#{params_name}"\n}
      end
    end
  end

  register Funkifize::Commands::Params::Create, "create", "create RESOURCE_NAME ACTION_NAME", "Create params for specified resource and action"
end
