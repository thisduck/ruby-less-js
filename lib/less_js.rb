require 'execjs'
require 'less_js/source'

module LessJs
  EngineError      = ExecJS::RuntimeError
  CompilationError = ExecJS::ProgramError

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
      @version ||= contents[/Less.js Compiler v([\d.]+)/, 1]
    end

    def self.context
      @context ||= ExecJS.compile(contents)
    end
  end

  class << self
    def version
      Source.version
    end

    # Compile a script (String or IO) to CSS.
    def compile(script, options = {})
      script = script.read if script.respond_to?(:read)

      code = <<-EOS
       (function(input) {
         var resp = "error";
         new(less.Parser)().parse(input, function(error, tree) {
           resp = [error, tree.toCSS()]
         });
        return resp;
      })
      EOS

      (error, response) = Source.context.call(code, script)
      raise CompilationError, error if error
      response
    end
  end
end
