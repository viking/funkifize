module Funkifize
  module Commands
    class App < Command
      def run(argv = [])
        subcommand = argv.shift
        klass =
          case subcommand
          when "create" then App::Create
          else
            nil
          end

        if klass.nil?
          $stderr.puts "Usage: funkifize [opts] app <command> <args>"
          $stderr.puts "Commands: create"
        else
          command = klass.new(options)
          command.run(argv)
        end
      end

      class Create < Command
        attr_reader :app_name, :app_constant, :author, :email, :github_username

        def run(argv = [])
          @app_name = argv.shift

          if @app_name.nil?
            $stderr.puts "Usage: funkifize [opts] app create <name>"
            return
          end

          setup
          create_directories
        end

        def setup
          if options[:app_constant]
            @app_constant = options[:app_constant]
          else
            @app_constant = app_name.gsub(/(?:[_-]+|^)(.)/) { $1.upcase }
          end

          git_author_name = `git config user.name`.chomp rescue ""
          @author = git_author_name.empty? ? "TODO: Write your name" : git_author_name

          git_user_email = `git config user.email`.chomp rescue ""
          @email = git_user_email.empty? ? "TODO: Write your email address" : git_user_email

          @github_username = `git config github.user`.chomp rescue ""
        end

        def create_directories
          directory("app", app_name)
        end
      end
    end
  end
end
