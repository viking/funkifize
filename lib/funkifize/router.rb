module Funkifize
  class Router < Thor
    class Create < Thor::Group
      include Thor::Actions
      include Helpers
      attr_reader :resource_constant, :router_name, :router_constant

      add_runtime_options!
      argument :resource_name, :desc => "Name of resource to make a router for"

      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))
      end

      def self.printable_commands(*args)
        # don't print this command twice
        []
      end

      def setup
        self.destination_root = options[:root] if options[:root]
        @router_options = { verbose: !options[:quiet] }
        @resource_constant = make_constant_name(resource_name)
        @router_name = "#{resource_name}_router"
        @router_constant = make_constant_name(@router_name)
      end

      def create_router_file
        empty_directory(File.join("lib", app_name, "routers"), @router_options)
        template("router.rb", File.join("lib", app_name, "routers", "#{router_name}.rb"), @router_options)
      end

      def add_autoload_instruction
        inside do
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# routers" or just
          # before the end of the main app module
          pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# routers.*\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\1  autoload :#{router_constant}, "#{app_name}/routers/#{router_name}"\n}
          inject_into_file(target, rplmnt, @router_options.merge(after: pattern))
        end
      end

      def setup_injector
        inside do
          target = File.join("lib", app_name, "builder.rb")

          # put line # just before the end of the bootstrap function
          pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
          rplmnt = %{\\1  injector.register_service('#{router_constant}', #{router_constant})\n}
          inject_into_file(target, rplmnt, @router_options.merge(after: pattern))
        end
      end

      def add_application_dependency
        inside do
          target = File.join("lib", app_name, "application.rb")
          add_class_dependency(target, "Application", router_name, router_constant)
        end
      end

      def add_default_route
        inside do
          target = File.join("lib", app_name, "application.rb")

          # put line # just before the end of the bootstrap function
          pattern = %r{
            ^([ \t]+)def\ initialize.*?\n
            \1\ \ @routes\ =\ \[\n
            (\1\ \ \ \ .*?\n)*
            (?=\1\ \ \])
          }xm
          rplmnt = "\\1    { path: %r{^/#{pluralize(resource_name)}(?=/)?}, router: #{router_name} },\n"
          inject_into_file(target, rplmnt, @router_options.merge(after: pattern))
        end
      end
    end

    register Funkifize::Router::Create, "create", "create ROUTER_NAME", "Create router named ROUTER_NAME"
  end
end
