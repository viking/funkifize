module Funkifize
  module Commands
    class Repository < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then Repository::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] repository <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        include Funkifize::Helpers
        attr_reader :resource_name, :resource_constant, :repository_name,
          :repository_constant

        def run(argv = [])
          @resource_name = argv.shift

          if @resource_name.nil?
            $stderr.puts "Usage: funkifize [opts] repository create <name>"
            return
          end

          setup
          create_repository_file
          create_migration_file
          add_autoload_instruction
          setup_injector
        end

        def setup
          self.destination_root = options[:root] if options[:root]
          @resource_constant = make_constant_name(resource_name)
          @repository_name = "#{resource_name}_repository"
          @repository_constant = make_constant_name(@repository_name)
        end

        def create_repository_file
          empty_directory(File.join("lib", app_name, "repositories"))
          template("repository.rb", File.join("lib", app_name, "repositories", "#{repository_name}.rb"))
        end

        def create_migration_file
          dir = File.join("db", "migrate")
          empty_directory(dir)

          # calculate migration version
          last_version = Dir.glob("*.rb", base: dir).inject(0) do |ver, fn|
            md = fn.match(/^(\d+)/)
            if md
              [ver, md[1].to_i].max
            else
              ver
            end
          end

          filename = "%03d_create_%s.rb" % [last_version + 1, pluralize(resource_name)]
          template("migration.rb", File.join(dir, filename))
        end

        def add_autoload_instruction
          target = File.join("lib", "#{app_name}.rb")

          # put line either after a block starting with "# repositories" or just
          # before the end of the main app module
          pattern = /^(\s*)module #{app_constant}.*\n(?:\s*# repositories.*?\n(?=\n)|(?=\1end\s*))/m
          rplmnt = %{\\1  autoload :#{repository_constant}, "#{app_name}/repositories/#{repository_name}"\n}
          inject_into_file(target, rplmnt, pattern)
        end

        def setup_injector
          target = File.join("lib", app_name, "builder.rb")

          # put line # just before the end of the bootstrap function
          pattern = /^([ \t]*)def bootstrap.*?(?=^\1end\b)/m
          rplmnt = %{\\1  injector.register_service('#{repository_constant}', #{repository_constant})\n}
          inject_into_file(target, rplmnt, pattern)
        end
      end
    end
  end
end
