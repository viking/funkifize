class Funkifize::Commands::Entity < Thor
  class Create < Thor::Group
    include Thor::Actions
    include Funkifize::Helpers
    attr_reader :resource_constant, :entity_name, :entity_constant

    add_runtime_options!
    argument :resource_name, :desc => "Name of resource to make a entity for"

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "templates"))
    end

    def self.printable_commands(*args)
      # don't print this command twice
      []
    end

    def setup
      self.destination_root = options[:root] if options[:root]
      @entity_options = { verbose: !options[:quiet] }
      @resource_constant = make_constant_name(resource_name)
    end

    def create_entity_file
      empty_directory(File.join("lib", app_name, "entities"), @entity_options)
      template("entity.rb", File.join("lib", app_name, "entities", "#{resource_name}.rb"), @entity_options)
    end

    def add_autoload_instruction
      inside do
        target = File.join("lib", "#{app_name}.rb")

        # put line either after a block starting with "# entities" or just
        # before the end of the main app module
        pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# entities.*?\n(?=\n)|(?=\1end\s*))/m
        rplmnt = %{\\1  autoload :#{resource_constant}, "#{app_name}/entities/#{resource_name}"\n}
        inject_into_file(target, rplmnt, @entity_options.merge(after: pattern))
      end
    end

    def setup_injector
      inside do
        target = File.join("lib", app_name, "builder.rb")

        # put line # just before the end of the bootstrap function
        pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
        rplmnt = %{\\1  injector.register_service('#{resource_constant}', #{resource_constant})\n}
        inject_into_file(target, rplmnt, @entity_options.merge(after: pattern))
      end
    end
  end

  register Funkifize::Commands::Entity::Create, "create", "create ENTITY_NAME", "Create entity named ENTITY_NAME"
end
