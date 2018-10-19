module Funkifize
  module Actions
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

        if !@config.has_key?(:instance_vars) || @config[:instance_vars]
          @content.insert(md.begin(3), "#{md[1]}    @#{dependency_name} = #{dependency_name}\n")
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
