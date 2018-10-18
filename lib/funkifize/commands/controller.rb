class Funkifize::Commands::Controller < Thor
  class Create < Thor::Group
    include Thor::Actions
    include Funkifize::Helpers
    attr_reader :resource_constant, :controller_name, :controller_constant

    add_runtime_options!
    argument :resource_name, :desc => "Name of resource to make a controller for"

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "templates"))
    end

    def self.printable_commands(*args)
      # don't print this command twice
      []
    end

    def setup
      self.destination_root = options[:root] if options[:root]
      @controller_options = { verbose: !options[:quiet] }
      @resource_constant = make_constant_name(resource_name)
      @controller_name = "#{resource_name}_controller"
      @controller_constant = make_constant_name(@controller_name)
    end

    def create_controller_file
      empty_directory(File.join("lib", app_name, "controllers"), @controller_options)
      template("controller.rb", File.join("lib", app_name, "controllers", "#{controller_name}.rb"), @controller_options)
    end

    def add_autoload_instruction
      inside do
        target = File.join("lib", "#{app_name}.rb")

        # put line either after a block starting with "# controllers" or just
        # before the end of the main app module
        pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# controllers.*\n(?=\n)|(?=\1end\s*))/m
        rplmnt = %{\1  autoload :#{controller_constant}, "#{app_name}/controllers/#{controller_name}"\n}
        inject_into_file(target, rplmnt, @controller_options.merge(after: pattern))
      end
    end

    def setup_injector
      inside do
        target = File.join("lib", app_name, "builder.rb")

        # put line # just before the end of the bootstrap function
        pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
        rplmnt = %{\\1  injector.register_service('#{controller_constant}', #{controller_constant})\n}
        inject_into_file(target, rplmnt, @controller_options.merge(after: pattern))
      end
    end
  end

  register Funkifize::Commands::Controller::Create, "create", "create CONTROLLER_NAME", "Create controller named CONTROLLER_NAME"
end
