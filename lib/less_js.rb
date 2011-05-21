require 'execjs'
require 'less_js/source'

module LessJs
  class ParseError < StandardError; end

  module Source
    def self.path
      @path ||= ENV['LESSJS_SOURCE_PATH'] || bundled_path
    end

    def self.path=(path)
      @contents = @version = @context = nil
      @path = path
    end

    def self.contents
      @contents ||= File.read(path)
    end

    def self.version
      @version ||= contents[/LESS - Leaner CSS v([\d.]+)/, 1]
    end

    def self.context
      @context ||= ExecJS.compile <<-EOS
        #{contents}

        function compile(data) {
          var result;
          new less.Parser().parse(data, function(error, tree) {
            result = [error, tree.toCSS()];
          });
          return result;
        }
      EOS
    end
  end

  class << self
    def version
      Source.version
    end

    # Compile a script (String or IO) to CSS.
    def compile(script, options = {})
      script = script.read if script.respond_to?(:read)
      error, data = Source.context.call('compile', script)

      if error
        raise ParseError, error['message']
      else
        data
      end
    end
  end
end
