module Funkifize
  module Helpers
    def make_constant_name(name)
      name.gsub(/(?:[_-]+|^)(.|$)/) { $1.upcase }
    end

    def app_name
      unless defined? @app_name
        inside do
          # look for gemspec file in current directory
          gemspecs = Dir['*.gemspec']
          if gemspecs.empty?
            raise "Not inside a funkifized application (missing gemspec)"
          end

          if options[:app_name]
            app_name = options[:app_name]
            if !gemspecs.include?("#{app_name}.gemspec")
              raise %{Not inside a funkifized application (missing "#{app_name}.gemspec")}
            end
          else
            app_name = gemspecs[0][/^(.+?)(?=\.gemspec$)/]
          end

          # do some rudimentary tests to make sure code generation will succeed
          if !File.exist?(File.join('lib', "#{app_name}.rb"))
            raise "Not inside a funkifized application (missing lib/#{app_name}.rb)"
          elsif !File.exist?(File.join('lib', app_name, 'application.rb'))
            raise "Not inside a funkifized application (missing lib/#{app_name}/application.rb)"
          elsif !File.exist?(File.join('lib', app_name, 'builder.rb'))
            raise "Not inside a funkifized application (missing lib/#{app_name}/builder.rb)"
          end

          @app_name = app_name
        end
      end

      @app_name
    end

    def app_constant
      unless defined? @app_constant
        if options[:app_constant]
          @app_constant = options[:app_constant]
        else
          @app_constant = make_constant_name(app_name)
        end
      end
      @app_constant
    end

    def add_class_dependency(filename, class_name, dependency_name, dependency_constant, config = {})
      action Actions::AddClassDependency.new(self, filename, class_name, dependency_name, dependency_constant, config)
    end

    def pluralize(word)
      ActiveSupport::Inflector.pluralize(word)
    end
  end
end
