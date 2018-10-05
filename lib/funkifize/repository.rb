module Funkifize
  class Repository < Thor
    class Create < Thor::Group
      include Thor::Actions
      include Helpers
      attr_reader :resource_constant, :repository_name, :repository_constant

      add_runtime_options!
      argument :resource_name, :desc => "Name of resource to make a repository for"

      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))
      end

      def self.printable_commands(*args)
        # don't print this command twice
        []
      end

      def setup
        self.destination_root = options[:root] if options[:root]
        @repository_options = { verbose: !options[:quiet] }
        @resource_constant = make_constant_name(resource_name)
        @repository_name = "#{resource_name}_repository"
        @repository_constant = make_constant_name(@repository_name)
      end

      def create_repository_file
        empty_directory(File.join("lib", app_name, "repositories"), @repository_options)
        template("repository.rb", File.join("lib", app_name, "repositories", "#{repository_name}.rb"), @repository_options)
      end

      def add_autoload_instruction
        inside do
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# repositories" or just
          # before the end of the main app module
          pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# repositories.*\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\1  autoload :#{repository_constant}, "#{app_name}/repositories/#{repository_name}"\n}
          inject_into_file(target, rplmnt, @repository_options.merge(after: pattern))
        end
      end

      def setup_injector
        inside do
          target = File.join("lib", app_name, "builder.rb")

          # put line # just before the end of the bootstrap function
          pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
          rplmnt = %{\\1  injector.register_service('#{repository_constant}', #{repository_constant})\n}
          inject_into_file(target, rplmnt, @repository_options.merge(after: pattern))
        end
      end
    end

    register Funkifize::Repository::Create, "create", "create REPOSITORY_NAME", "Create repository named REPOSITORY_NAME"
  end
end
