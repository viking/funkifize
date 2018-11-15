module Funkifize
  class Command
    TEMPLATE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "templates"))
    attr_reader :options, :destination_root

    def initialize(options = {})
      @options = options
    end

    def destination_root=(path)
      @destination_root = path
    end

    def empty_directory(target_path)
      target_path = process_target_path(target_path)
      FileUtils.mkdir_p(target_path)
    end

    def directory(template_path, target_path, env = binding)
      target_path = process_target_path(target_path)
      empty_directory(target_path)

      template_root = File.expand_path(template_path, TEMPLATE_ROOT)
      Dir.children(template_root).each do |template_filename|
        template_full_path = File.join(template_root, template_filename)

        target_filename = template_filename.gsub(/%(\w+)%/) { |_| eval($1, env) }
        target_full_path = File.join(target_path, target_filename)

        if File.directory?(template_full_path)
          directory(template_full_path, target_full_path)

        elsif template_filename =~ /\.tt$/
          target_full_path.sub!(/\.tt$/, "")

          if !File.exist?(target_full_path)
            template = ERB.new(File.read(template_full_path), nil, "-")
            File.open(target_full_path, "w") { |f| f.write(template.result(env)) }
          end
        elsif !File.exist?(target_full_path)
          FileUtils.cp(template_full_path, target_full_path)
        end
      end
    end

    def template(template_filename, target_path, env = binding)
      target_path = process_target_path(target_path)

      if !File.exist?(target_path)
        template_full_path = File.expand_path("#{template_filename}.tt", TEMPLATE_ROOT)
        template = ERB.new(File.read(template_full_path), nil, "-")
        File.open(target_path, "w") { |f| f.write(template.result(env)) }
      end
    end

    def inject_into_file(target_path, replacement, pattern)
      target_path = process_target_path(target_path)

      data = File.read(target_path)
      if data.sub!(pattern, '\0' + replacement)
        File.open(target_path, 'w') { |f| f.write(data) }
      end
    end

    def add_class_dependency(target_path, class_name, dependency_name, dependency_constant, config = {})
      content = File.read(target_path)

      #
      # add dependency
      #
      pattern = %r{
        ^(\ *)class\ #{class_name}\b    # find beginning of class
        .*?\n                           # match until dependencies method
        \1\ \ def\ self\.dependencies\n
        \1\ \ \ \ %w\{([^\}]*)\}\n      # capture current dependencies
        \1\ \ end\b
      }xm
      md = content.match(pattern)
      if md.nil?
        return
      end

      if md[2] == ""
        # no dependencies yet
        content.insert(md.begin(2), dependency_constant)
      else
        # insert after current dependencies
        content.insert(md.end(2), " " + dependency_constant)
      end

      #
      # add initializate parameter
      #
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

      md = content.match(pattern)
      if md.nil?
        say_status :failed_pattern, :red
        return
      end

      if !config.has_key?(:instance_vars) || config[:instance_vars]
        content.insert(md.begin(3), "#{md[1]}    @#{dependency_name} = #{dependency_name}\n")
      end

      if md[2] == ""
        # no parameters yet
        content.insert(md.begin(2), "(#{dependency_name})")
      elsif md[2] == "("
        content.insert(md.begin(2)+1, "#{dependency_name}")
      else
        # insert after current dependencies
        content.insert(md.end(2), ", " + dependency_name)
      end

      #
      # save content
      #
      File.open(target_path, "wb") { |file| file.write(content) }
    end

    private

    def process_target_path(path)
      if destination_root
        File.expand_path(path, destination_root)
      else
        path
      end
    end
  end
end
