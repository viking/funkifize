module Funkifize
  module Helpers
    def make_constant_name(name)
      name.gsub(/(?:[_-]+|^)(.|$)/) { $1.upcase }
    end

    def app_name
      unless defined? @app_name
        inside do
          # look for gemspec file in current directory
          files = Dir['*.gemspec']
          if files.empty?
            raise "Not inside a funkifized application (no gemspec)"
          end

          app_name = files[0][/^(.+?)(?=\.gemspec$)/]

          # do some rudimentary tests to make sure code generation will succeed
          if !File.exist?(File.join('lib', "#{app_name}.rb"))
            raise "Not inside a funkifized application (no lib/#{app_name}.rb)"
          elsif !File.exist?(File.join('lib', app_name, 'application.rb'))
            raise "Not inside a funkifized application (no lib/#{app_name}/application.rb)"
          elsif !File.exist?(File.join('lib', app_name, 'builder.rb'))
            raise "Not inside a funkifized application (no lib/#{app_name}/builder.rb)"
          end

          @app_name = app_name
        end
      end

      @app_name
    end

    def app_constant
      @app_constant ||= make_constant_name(app_name)
    end

    def add_class_dependency(filename, class_name, dependency_name, dependency_constant, config = {})
      action Actions::AddClassDependency.new(self, filename, class_name, dependency_name, dependency_constant, config)
    end

    def pluralize(word)
      ActiveSupport::Inflector.pluralize(word)
    end
  end
end
