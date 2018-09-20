module Funkifize
  class App < Thor
    class Create < Thor::Group
      include Thor::Actions
      attr_reader :constant_name, :author, :email, :github_username

      argument :app_name, :desc => "Application name"

      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))
      end

      def self.printable_commands(*args)
        # don't print this command twice
        []
      end

      def setup
        @constant_name = app_name.gsub(/([_-]+|^)(.)/) { $1.to_s + $2.upcase }

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

    register Funkifize::App::Create, "create", "create APP_NAME", "Create application named APP_NAME"
  end
end
