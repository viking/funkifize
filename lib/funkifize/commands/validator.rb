class Funkifize::Commands::Validator < Thor
  class Create < Thor::Group
    include Thor::Actions
    include Funkifize::Helpers
    attr_reader :validators_module_name, :validators_module_constant, :validator_name,
      :validator_constant

    add_runtime_options!
    argument :resource_name, :desc => "Name of resource to make a validator class for"
    argument :action_name, :desc => "Name of action to create a validator class for"

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "templates"))
    end

    def self.printable_commands(*args)
      # don't print this command twice
      []
    end

    def setup
      self.destination_root = options[:root] if options[:root]
      @validator_options = { verbose: !options[:quiet] }
      @validators_module_name = "#{resource_name}_validators"
      @validators_module_constant = make_constant_name(@validators_module_name)
      @validator_name = action_name
      @validator_constant = make_constant_name(@validator_name)
    end

    def create_validators_module_file
      empty_directory(File.join("lib", app_name, "validators"), @validator_options)
      template("validators_module.rb", File.join("lib", app_name, "validators", "#{validators_module_name}.rb"), @validator_options.merge(skip: true))
    end

    def setup_autoload_for_validators_module
      target = File.join("lib", "#{app_name}.rb")

      # put line either after a block starting with "# validator" or just
      # before the end of the main app module
      pattern = /^([ \t]*)module #{app_constant}.*?\n(?:\s*# validators.*?\n(?=\n)|(?=\1end\s*))/m
      rplmnt = %{\\1  autoload :#{validators_module_constant}, "#{app_name}/validators/#{validators_module_name}"\n}
      inject_into_file(target, rplmnt, @validator_options.merge(after: pattern))
    end

    def create_validator_file
      empty_directory(File.join("lib", app_name, "validators", validators_module_name), @validator_options)
      template("validator.rb", File.join("lib", app_name, "validators", validators_module_name, "#{validator_name}.rb"), @validator_options)
    end

    def setup_autoload_for_validator_class
      inject_into_module(File.join("lib", app_name, "validators", "#{validators_module_name}.rb"), validators_module_constant, @validator_options) do
        %{    autoload :#{validator_constant}, "#{app_name}/validators/#{validators_module_name}/#{validator_name}"\n}
      end
    end
  end

  register Funkifize::Commands::Validator::Create, "create", "create RESOURCE_NAME ACTION_NAME", "Create validator for specified resource and action"
end
