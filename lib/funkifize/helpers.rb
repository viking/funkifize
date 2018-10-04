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
      action AddClassDependency.new(self, filename, class_name, dependency_name, dependency_constant, config)
    end

    class AddClassDependency < Thor::Actions::EmptyDirectory
      attr_reader :class_name, :dependency_name, :dependency_constant

      def initialize(base, destination, class_name, dependency_name, dependency_constant, config)
        super(base, destination, {:verbose => true}.merge(config))
        @class_name = class_name
        @dependency_name = dependency_name
        @dependency_constant = dependency_constant
      end

      def invoke!
        if !File.exist?(destination)
          say_status :file_missing, :red
          return
        end
        @content = File.read(destination)

        add_dependency
        add_initialize_parameter
        save_content
      end

      def revoke!
      end

      private

      def add_dependency
        pattern = %r{
          ^(\ *)class\ #{class_name}\b    # find beginning of class
          .*?\n                           # match until dependencies method
          \1\ \ def\ self\.dependencies\n
          \1\ \ \ \ %w\{([^\}]*)\}\n      # capture current dependencies
          \1\ \ end\b
        }xm
        md = @content.match(pattern)
        if md.nil?
          say_status :failed_pattern, :red
          return
        end

        if md[2] == ""
          # no dependencies yet
          @content.insert(md.begin(2), dependency_constant)
        else
          # insert after current dependencies
          @content.insert(md.end(2), " " + dependency_constant)
        end
      end

      def add_initialize_parameter
        pattern = %r{
          ^(\ *)class\ #{class_name}\b # find beginning of class
          .*?\n                        # match until initialize method

          # capture current parameters
          \1\ \ def\ initialize(\([^)]*(?=\))|)

          # method body (no capture)
          (?:.*?\n)*?

          # capture end of function for possible insertion
          (\1\ \ end\b)
        }xm

        md = @content.match(pattern)
        if md.nil?
          say_status :failed_pattern, :red
          return
        end

        if md[2] == ""
          # no parameters yet
          @content.insert(md.begin(2), "(#{dependency_name})")
        elsif md[2] == "("
          @content.insert(md.begin(2)+1, "#{dependency_name}")
        else
          # insert after current dependencies
          @content.insert(md.end(2), ", " + dependency_name)
        end
      end

      def save_content
        File.open(destination, "wb") { |file| file.write(@content) }
      end
    end
  end
end
