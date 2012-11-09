# see String class in template.rb

class CommandInterface # should this actually be a mix-in?
  # have ext, stdout, and other_opts, and environ
  # for ext, 1st check environment for default-value, otherwise set to .nii.gz
  
  # for environ have mixins with FSL, AFNI, and Freesurfer
  # for FSL, will auto-check the extensions and then change the FSL output variable for that command
  # for Freesurfer (or more specifically for ReconAll), might want something that would convert the inputs/outputs to be your format with mri_convert
  
  # this includes a run command?
  # add setting of envir
  
  attr_accessor :inputs, :outputs
  
  GLOBAL_OPT_CLASSES = ["CommandInterface", "Base"]
  
  class << self
    
    def new(*args, options={})
      # Since we are now sure that no more inputs or outputs will be added
      # we will setup the input and output specs
      @input_spec  = 
      
      @output_spec = self.const_set("OutputSpec", Class.new)
      
      def create_io_specs
        [:input, :output].each do |in_or_out|
          klass_name  = in_or_out.to_s.capitalize + "Spec"
          spec        = self.const_set(klass_name, Class.new)
          spec.class_eval do 
            @options.each_pair do |name, settings|
              next if not settings[in_or_out]
              property name.to_sym, s
            end
            
            @options.each_pair do |k,sub_options| # k = opt-level (doesn't really matter here)
              sub_options[io].each_pair do |name, settings|
                property name.to_sym, settings.select{|k| PROPERTY_KEYS.include? k}
              end
            end
          end
        end
        
        
        InputSpec.class_eval do
          input_options.each doesn |name, desc, settings|
            property name.to_sym, settings.select{|k| PROPERTY_KEYS.include? k}
          end
        end
        
      end
      
      
      begin
        Object.const_get(approach.camelize.to_sym)
        input_spec = A.const_set("#{approach.camelize}InputSpec", Class.new)
        input_spec.send(:include, SmartProperties)
        input_spec.send(:property, :subject, :required => true)
        
        .new(*args, options)
      rescue NameError
        raise NameError "The approach #{approach} was not recognized"
      end
    end
        
    def validates_that(&block, options={})
      @validations ||= []
      @validations  << block
    end
    
    def option_level
      # Options are global if they come from this class or a Base class of any approach
      GLOBAL_OPT_CLASSES.include?(self.name) ? :global : self.name.underscore.to_sym
    end
    
    def add_option(name, desc, settings={})
      settings       = default_settings.merge(:desc => desc).merge(settings)
      # TODO: add warning if name already in options
      @options[name] = settings
      return self
    end
    
    def add_input(name, desc, settings={})
      settings = settings.merge(:input => true)
      self.add_option(*args, settings)
    end
    
    def add_output(name, desc, settings={})
      settings = settings.merge(:output => true)
      self.add_option(name, desc, settings)
    end
    
    def update_option(name, settings={})
      settings = default_settings.merge(settings)
      # TODO: handle case when name doesn't exist
      @options[name].update(settings)
      return self
    end
    
    def update_input(name, settings={})
      settings = settings.merge(:input => true)
      self.update_option(name, settings)
    end
    
    def update_output(name, settings={})
      settings = settings.merge(:output => true)
      self.update_option(name, settings)
    end
    
    def default_settings
      {:optlevel => option_level, :input => false, :output => false}
    end
    
    
    private
      
      def set_io_properties
        InputSpec.class_eval do
          input_options.each do |name, desc, settings|
            property name.to_sym, settings.select{|k| PROPERTY_KEYS.include? k}
          end
        end
      end
    
    def short_from(name)
      name.to_s.chars.each do |c|
        next if @used_short.include? c || c == "_"
        return c  # returns from short_from method
      end
    end
  
    def parse_cli(arguments = ARGV)
      # need @used_short
      options = @input_options + @output_options
      @result = (@default_values || {}).clone # reset or new
      # 
      
      @optionparser ||= OptionParser.new do |p| # prepare only once
        
      end
      
    end
    
  end
  
  
  def add_output
    
  end
  

  # 1. Set properties in InputSpec / OutputSpec
  # 2. Set the options for argument parsing
  # 3. Save settings for generating the command (argstr and position)

  
  add_option :env, "Environmental options", :type => ?
  add_output :stdout, "Standard Output", :type => :string
  add_option :other_opts, "Other options", :type => :string
  add_option :ext, "Output file extension", :type => :string
  
  
  :int, :integer, :string, :double, :float
  
  def parse_integer_parameter param, arg
  599	
      raise CommandlineError, "option '#{arg}' needs an integer" unless param =~ /^\d+$/
  600	
      param.to_i
  601	
    end
  602	
  603	
    def parse_float_parameter param, arg
  604	
      raise CommandlineError, "option '#{arg}' needs a floating-point number" unless param =~ FLOAT_RE
  605	
      param.to_f
  606	
    end
  607	
  608	
    def parse_io_parameter param, arg
  609	
      case param
  610	
      when /^(stdin|-)$/i; $stdin
  611	
      else
  612	
        require 'open-uri'
  613	
        begin
  614	
          open param
  615	
        rescue SystemCallError => e
  616	
          raise CommandlineError, "file or url for option '#{arg}' cannot be opened: #{e.message}"
  617	
        end
  618	
      end
  619	
    end
  
end

# SkullStrip(:afni_anat, :in)
# cmd = SkullStrip.new(:afni_anat, :infile => "/path/to/x")
# cmd.inputs.orig_vol = true
# cmd.outputs.outfile = x

# set type of input (with setter)
# check if required inputs have been set
# set defsult values

module TestMe
  def 
end

reset

require 'smart_properties'

module Conversions
  def to_string(x)
    String(x)
  end
  
  def to_integer(x)
    Integer(x)
  end
  
  def to_float(x)
    Float(x)
  end
  
  def to_symbol(x)
    to_string(x).to_sym
  end
end

class Message
  include SmartProperties
  extend Conversions
  
  property :subject, 
    :type => :integer, 
    :choices => [:low, :normal, :high], 
    :range => {:min => 2, :max => 5}
    :length => {:max => 6}, # for string or symbol or can have just 1 argument
    :nargs => 2,        # number of arguments for array or hash
    :default => :normal, 
    :required => true   # this is checked 
      
    :converts => lambda {|x| ...}
    :validates => lambda {|x| ...}
  
  
  property :subject, 
    :type => :integer, 
    :enum => [:low, :normal, :high], 
    :range => [nil,3],  # for int or float
    :length => [nil,5], # for string or symbol or can have just 1 argument
    :nargs => 2,        # number of arguments for array or hash
    :default => :normal, 
    :required => true   # this is checked 
    
    :validation => lambda {|x| ...}, 
    :message => "Sample Error Message"

  
  property :subject,  :converts => method(:to_integer), :required => true

  property :body,     :converts => lambda {|x| Integer(x)}

  property :priority, :converts => :to_sym, 
                      :accepts  => [:low, :normal, :high],
                      :default  => :normal, 
                      :required => true
end

class A
  class InputSpec
    include SmartProperties
  end
  
  class OutputSpec
    include SmartProperties
  end
end

module A
  ARG_TYPES = [:boolean, :integer, :string, :float, :symbol, :path, :array, :hash]
end

module A
  def variable
    "Variable '#{self.name}'"
  end
   
    def converts_hash(value)
      raise TypeError, "#{variable} must be a hash and not '#{value}'" unless value.is_a? Hash
      value
    end
  
end

input_spec = A.const_get("InputSpec")
input_spec.send(:property, :subject, :required => true)

class B < A
end

class C < A
end

# :type => :int, :string, :float, :path, :symbol, :array, :hash
#   :converts input :to_i, :to_s, :to_f, :to_p,

SkullStrip::InputSpec.class_eval do
  
end


cmd = skull_strip :anat_afni, :infile => ...


module SkullStrip
  def skull_strip(approach, options={})
    # find the associated class within this module
    # if it doesn't exist maybe try to find the closest matching class and spit back a useful error to the user
  end
  
  def cmdline(options = ARGV)
    # MyModule.constants.select {|c| Class === MyModule.const_get(c)}
  end
  
  # So the base stuff has global_options
  # All the other stuff has sub_options
  
  # Want another interface to accept options from the command-line and parse all of them
  
  # Want one interface to accept inputs and outputs from ruby
  
  
  class Base < CommandInterface
    # can you have an input be pathname? ...
    # => see http://gitorious.org/trollop/mainline/merge_requests/8
  
    # _fun_name = 'skullstrip' # in future allow this
    # _cmd_name = 'skullstrip' # in future allow this
  
    version = "0.1 (c) Zarrar Shehzad"
    banner = "TODO"
  
    add_input :infile, "Input image with skull", :required => true, :type => :pathname
    add_output :outfile, "Image with skull removed", :type => :pathname
    add_output :mask, "Simple mask of what's brain", :type => :pathname
    
    validates_that { not outputs.outfile.nil? or not outputs.mask.nil? }, 
      :message => "You must specifiy the path to either the output brain image" + 
                  "(outfile) or output brain mask (mask)."
    
  end
  
  class AfniAnat < Base
    _cmd = "3dSkullStrip"
  
    update_input :infile, :argstr => "-input %s"
    add_option :orig_vol, :argstr => "-orig_vol", :type => :boolean, 
      :default => true
    add_option :norm_vol, :argstr => "-norm_vol", :type => :boolean
    
    private
    
      def autogen_opts
        cmdline_help = `#{_cmd}`
    
        # Don't want any SUMA related stuff
        end_i = cmdline_help.index("SUMA communication options") - 1
        cmdline_help = cmdline_help[0..end_i]
    
        regex = /
          (?<indent>^[ ]*)
          [-]
            (?<name>\w+)
            (?:[ ](?<arg>\w+))?
          [:][ ]*
            (?<desc>.+?)
          (?=                     # Will stop either when
            (?:\n\k<indent>[-])   # a. have a new option
              |
            (?:\n[ ]{0,2}\S)      # b. have non-indented text
          )  
        /mx
        names = regex.names.collect{|x| x.to_sym}

        opts = cmdline_help.scan(regex).collect do |match|
          h = Hash[names.zip(match)]
          h[:argstr]    = "-#{h[:name]}"
          if not h[:desc].nil?
            desc        = h[:desc].split("\n")
            if desc.count > 1
              indent    = desc[1].match(/\s+/).to_s
              # want to strip the main indentation but keep any extra stuff
              desc      = desc.collect{|x| x.rstrip.sub(indent, "")}
            else
              desc[0]   = desc[0].rstrip
            end
            desc        = desc.select{|x| not x.empty?}
            h[:desc]    = desc.join("\n")
          end
          h[:type]      = :string if not h[:arg].nil?  
          h.delete(:indent)
          h.delete(:arg)
          h.delete_if {|k,v| v.nil?}
        end
        
        return opts
      end      
  end
  
  class AfniFunc < Base
    _cmd = "3dAutomask"
    update_input :infile, :position => -1
    update_output :outfile, :argstr => "-apply_prefix %s"
    update_output :mask, :argstr => "-prefix %s"
  end


end

  class Bet < Base
    _cmd = "bet"
    infile.with :position => 
  end

  class Freesurfer < Base
    # see: http://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/SkullStripFix
  
    # do 3dresample -master #{infile} -dxyz #{infile.x} etc
  end

  class Bse < Base
  
  end

  class Robex < Base
  
  end
  
end





