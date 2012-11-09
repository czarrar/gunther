module Gunther

  require 'Open3'
  require 'FileUtils'

  # Cross-platform way of finding an executable in the $PATH.
  # see http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
  #
  #   which('ruby') #=> /usr/bin/ruby
  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = "#{path}#{File::SEPARATOR}#{cmd}#{ext}"
        return exe if File.executable? exe
      }
    end
    return nil
  end

  class Command
  
    DEFAULT_OPTIONS = {
      :dry_run            => false, 
      :check_inputs       => true, 
      :check_outputs      => true, 
      :auto_overwrite     => true, 
      :overwrite_outputs  => false, 
      :raise_exceptions   => true, 
      :print_output       => true, 
      :merge_streams      => false  # only for output from command
    }
  
    attr_accessor :cmd, :inputs, :outputs, :cwd, :env, :options
    attr_reader :errors, :thread, :returncode, :pid, :stdout, :stderr
  
    def initialize(cmd, cmd_options={})
      self.cmd      = cmd.strip
      self.inputs   = cmd_options.delete(:inputs){ [] }
      self.outputs  = cmd_options.delete(:outputs){ [] }
      self.cwd      = cmd_options.delete(:cwd){ Dir.pwd }
      self.env      = cmd_options.delete(:env){ {} }
      self.options  = DEFAULT_OPTIONS.clone
      cmd_options.each do |name, value|
        raise "Unknown option '#{name}'" if not DEFAULT_OPTIONS.include? name
        self.options[name] = value
      end
    
      @before_run   = proc {}
      @during_run   = nil
      @after_run    = proc {}
    
      @errors       = []
    
      reset_vars
    end
  
    def progname
      cmd.match(/^(\S+)\s*/)
      $1
    end
  
    def select_missing(paths)
      paths.select do |path|
        not File.exists? path
      end
    end
  
    def select_existing(paths)
      paths.select do |path|
        File.exist? path
      end
    end
  
    def errors?
      errors.count > 0
    end
  
    def any_inputs_missing?
      missing_inputs = select_missing(inputs).join(", ")
      error "Missing input(s): #{missing_inputs}" if not missing_inputs.empty?
      not missing_inputs.empty?
    end
  
    def delete_outputs
      select_existing(outputs).each do |f|
        @stdout << "Deleting output: #{f}\n"
        File.delete f 
      end
    end
  
    def any_outputs_exist?
      existing_outputs = select_existing(outputs).join(", ")
      error "Output(s) exist: #{existing_outputs}" if not existing_outputs.empty?
      not existing_outputs.empty?
    end
  
    def any_outputs_missing?
      missing_outputs = select_missing(outputs).join(", ")
      error "Missing output(s): #{missing_outputs}" if not missing_outputs.empty?
      not missing_outputs.empty?
    end
  
    def rerun?
      inputs.any? {|input| FileUtils.uptodate?(input, outputs) }
    end
  
    def ran?
      not @returncode.nil?
    end
  
    def before_run( &block )
      @before_run = block
    end
  
    def during_run( &block )
      @during_run = block
    end
  
    def after_run( &block )
      @after_run = block
    end
  
    def env?
      env.is_a? Hash
    end
  
    def cwd?
      File.directory? cwd
    end
  
    def cmd?
      Dir.chdir(cwd) { File.file?(progname) or not which(progname).nil? }
    end
  
    def executable?
      Dir.chdir(cwd) { File.executable? progname }
    end
  
    def can_run?
      return error "Environment variable must be a hash" if not env?
      return error "Working directory '#{cwd}' does not exist" if not cwd?
      return error "Command '#{progname}' was not found in path" if not cmd?
      return error "Command '#{progname}' is not executable" if not executable?
      return error "Can only run '#{cmd}' once (try rerun instead)." if ran?
      return true
    end
  
    def run
      @before_run.call( self )
    
      @stdout    << cmd + "\n"
      return nil if not can_run?
    
      if @during_run.nil?
        @during_run = options[:print_output] ? \
                        method(:verbose_during_run) : method(:quiet_during_run)
      end
    
      if options[:dry_run]
        stdin,stdout,stderr,thread = Open3.popen3(env, "echo 'DRY-RUN: command not run'", 
                                                    :chdir => cwd)
      else
        delete_outputs if options[:overwrite_outputs] or (options[:auto_overwrite] and rerun?)
        if (options[:check_inputs] and any_inputs_missing?) or \
           (options[:check_outputs] and any_outputs_exist?)        
          stdin,stdout,stderr,thread = Open3.popen3(env, "echo 'ERROR: command not run'", 
                                                      :chdir => cwd)
        elsif options[:merge_streams]
          stdin,stdout,thread = Open3.popen2e(env, cmd, :chdir => cwd)
          stderr = StringIO.new
          any_outputs_missing?
        else
          stdin,stdout,stderr,thread = Open3.popen3(env, cmd, :chdir => cwd)
          any_outputs_missing?
        end
      end
    
      begin
        stdout,stderr = @during_run.call( self, stdout, stderr, thread )
      rescue LocalJumpError
        error "Unexpected return from during_run block. Must return [stdout,stderr]."
      end
      stdout      = stdout.is_a?(IO) ? stdout.read : stdout.to_s
      stderr      = stderr.is_a?(IO) ? stderr.read : stderr.to_s
    
      @thread     = thread
      @pid        = thread.pid
      @returncode = thread.value.to_i
      @stdout    << stdout
      @stderr    << stderr
      @was_run    = true
    
      if @returncode > 0
        error "Non-zero exit for command '#{progname}'"
        puts errors[-1] if options[:print_output]
      end
    
      @after_run.call( self, @stdout, @stderr, @returncode )
    
      returncode
    end
  
    def run!
      options[:raise_exceptions] = true
      run
    end
  
    def rerun
      reset_vars
      options[:overwrite_outputs] = true
      run
    end
  
    def rerun!
      options[:raise_exceptions] = true
      rerun
    end
  
    private
    
      def reset_vars
        @thread     = nil
        @pid        = nil
        @returncode = nil
        @stdout     = ""
        @stderr     = ""
        @was_run    = false
      end
  
      def error(msg)
        @stderr << "COMMAND ERROR: #{msg}\n"
        errors  << msg
        raise msg if options[:raise_exceptions]
        false
      end
    
      def verbose_during_run(obj, stdout, stderr, thread)
        puts obj.stdout if not obj.stdout.empty?
        puts obj.stderr if not obj.stderr.empty?
      
        save_stdout = ""
        save_stderr = ""
      
        until stdout.eof? and stderr.eof?
          cur_stdout = stdout.gets
          if not (cur_stdout.nil? or cur_stdout.empty?)
            save_stdout << cur_stdout + "\n"
            puts "OUT: #{cur_stdout}"
          end
          cur_stderr = stderr.gets
          if not (cur_stderr.nil? or cur_stderr.empty?)
            save_stderr << cur_stderr + "\n"
            puts "ERROR: #{cur_stderr}"
          end        
        end
        return [stdout, stderr]
      end
    
      def quiet_during_run(obj, stdout, stderr, thread)
        [stdout, stderr]
      end
    
  end

end
