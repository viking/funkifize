module Funkifize
  class Router < Thor
    class Create < Thor::Group
      include Thor::Actions
      include Helpers
      attr_reader :resource_constant, :router_name, :router_constant

      argument :resource_name, :desc => "Name of resource to make a router for"

      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))
      end

      def self.printable_commands(*args)
        # don't print this command twice
        []
      end

      def setup
        pushd(options[:chdir])
        @resource_constant = make_constant_name(resource_name)
        @router_name = "#{resource_name}_router"
        @router_constant = make_constant_name(@router_name)
      end

      def create_router_file
        empty_directory(File.join(app_name, 'lib', app_name, 'routers'))
        template('router.rb', File.join(app_name, 'lib', app_name, 'routers', "#{router_name}.rb"))
      end

      def teardown
        popd
      end
    end

    register Funkifize::Router::Create, "create", "create ROUTER_NAME", "Create router named ROUTER_NAME"
  end
end
