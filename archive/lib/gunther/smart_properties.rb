# This is a modified version of SmartProperties

require 'pathname'

class PropertyError < StandardError; end

##
# {SmartProperties} can be used to easily build more full-fledged accessors 
# for standard Ruby classes. In contrast to regular accessors, 
# {SmartProperties} support validation and conversion of input data, as well 
# as, the specification of default values. Additionally, individual 
# {SmartProperties} can be marked as required. This causes the runtime to
# throw an +ArgumentError+ whenever a required property has not been
# specified.
#
# In order to use {SmartProperties}, simply include the {SmartProperties} 
# module and use the {ClassMethods#property} method to define properties.
#
# @see ClassMethods#property 
#   More information on how to configure properties
#
# @example Definition of a property that makes use of all {SmartProperties} features.
#
#  property :language_code, :accepts => [:de, :en],
#                           :converts => :to_sym,
#                           :default  => :de,
#                           :required => true
#
module SmartProperties
  
  VERSION = "1.1.0" # modified...
  
  module Validations
        
    def variable
      "Variable '#{self.name}'"
    end
    
    # Below are actually conversions
  
    def converts_boolean(value)
      warn "#{variable} is of type #{value.class} but converting to boolean" unless value.is_a?(TrueClass) or value.is_a?(FalseClass) or value.is_a?(NilClass)
      !!value
    end
    
    def converts_integer(value)
      begin
        raise ArgumentError unless value.to_s =~ /\A[+-]?\d+\Z/
        Integer(value)
      rescue ArgumentError
        raise TypeError, "#{variable} must be an integer and not '#{value}'"
      end
    end
    
    def converts_string(value)
      String(value)
    end
    
    def converts_float(value)
      begin 
        Float(value)
      rescue ArgumentError
        raise TypeError, "#{variable} must be a floating point number and not '#{value}'"
      end
    end
    
    def converts_symbol(value)
      value.to_s.to_sym
    end
    
    def converts_path(value)
      begin
        Pathname(value)
      rescue TypeError
        raise TypeError, "#{variable} must be a string or pathname and not '#{value}'"
      end
    end
    
    def converts_array(value)
      warn "#{variable} is a hash of '#{value}' but converting to an Array" if value.is_a? Hash
      Array(value)
    end
    
    def converts_hash(value)
      raise TypeError, "#{variable} must be a hash and not '#{value}'" unless value.is_a? Hash
      value
    end
    
    
    # Below are validations
    def validates_choices(value, choices)
      choices = Array(choices)
      raise ":choices cannot be specified for hash values" if value.is_a? Hash  # maybe add ability to have choices with hash?
      raise PropertyError, "#{variable} must be one of the following: #{choices.join(', ')}" unless choices.include? value
      true
    end
    
    def validates_range(value, range)
      raise ":range can only be specified for numeric values" unless value.is_a? Numeric
      raise ":range must be a Hash" unless range.is_a? Hash
      raise ":range must either have keys :min or :max" unless range.has_key?(:min) or range.has_key?(:max)
      
      if (range[:min].present? and value < range[:min]) or (range[:max].present? and value > range[:max])
        error_message  = []
        error_message << "greater than #{range[:min]}" if range[:min].present?
        error_message << "less than #{range[:max]}" if range[:max].present?
        error_message << "not #{value}"
        raise PropertyError, "#{variable} must be" + error_message.join(" and ")
      end
      
      true
    end
    
    def validates_length(value, length)
      raise ":length can only be specified for string or path values" unless value.is_a?(String) or value.is_a?(Pathname)
      raise ":length must be a Hash" unless length.is_a? Hash
      raise ":length must either have keys :min or :max" unless length.has_key?(:min) or length.has_key?(:max)
      
      value = value.to_s # maybe do this first so any value can be accepted?
      if (length[:min].present? and value.length < length[:min]) or (length[:max].present? and value.length > length[:max])
        error_message  = []
        error_message << "greater than #{length[:min]}" if length[:min].present?
        error_message << "less than #{length[:max]}" if length[:max].present?
        error_message << "not #{value}"
        raise PropertyError, "#{variable} must be" + error_message.join(" and ")
      end
      
      true
    end
    
    def validates_nargs(value, nargs)
      raise ":nargs can only be specified for Array or Hash values" unless value.is_a?(Array) or value.is_a?(Hash)
      nargs = nargs.to_i  # TODO: add check if this fails
      
      raise PropertyError, "#{variable} must be an array of length #{nargs} and not #{value.count}" if value.count != nargs
    end
    
  end
  
  
  # for int or float
  
  # for str or symbol have length
  
  # for for array or hash have nargs
  
  class Property
    include Validations
        
    attr_reader :name, :type
    attr_reader :converter, :validator
    attr_reader :validations

    def initialize(name, attrs = {})      
      attrs = attrs.dup
      
      @name      = name.to_s.to_sym
      
      arg_types  = self.valid_arg_types
      @type      = (attrs.delete(:type) || :boolean).to_s.to_sym
      raise "Unrecognized type '#{@type}'. Must be one of the following: #{arg_types.join(', ')}" unless arg_types.include? @type
      
      @default   = attrs.delete(:default)
      @default ||= false if @type == :boolean
      @required  = !!attrs.delete(:required)  # note: !!nil => false
      
      @converter = attrs.delete(:converts) || proc {}
      @validator = attrs.delete(:validates) || proc {}
      
      validation_names = self.valid_validation_names
      @validations = {}
      attrs.each_pair do |key, value|
        skey = key.to_s.to_sym
        @validations[key] = attrs.delete(key) if validation_names.include? skey
      end
      
      if attrs.present?
        raise ArgumentError, "SmartProperties do not support the following configuration options: #{attrs.keys.join(', ')}."
      end
    end
    
    class << self
      def valid_arg_types
        instance_methods.
          select{|name| name =~ /\Aconverts_\w+\Z/ }.
          collect{|name| name.to_s.sub(/\Aconverts_/, "").to_sym }
      end
      
      def valid_validation_names
        instance_methods.
          select{|name| name =~ /\Avalidates_\w+\Z/ }.
          collect{|name| name.to_s.sub(/\Avalidates_/, "").to_sym }
      end
    end

    def required?
      @required
    end
    
    def default(scope)
      @default.kind_of?(Proc) ? scope.instance_exec(&@default) : @default
    end
    
    def convert!(value, scope)
      if converter.respond_to?(:call)
        value = scope.instance_exec(value, &converter)
      elsif converter.present?
        raise TypeError, "The converter for #{self.name} must be callable or nil."
      end
      if value.nil?
        return value
      else
        return send(:"converts_#{self.type}", value)
      end
    end
    
    def validate!(value, scope)
      if validator.respond_to?(:call)
        scope.instance_exec(value, &validator)
      elsif validator.present?
        raise TypeError, "The validator for #{self.name} must be callable or nil."
      end
      
      validations.each_pair do |name, settings|
        send(:"validates_#{name}", value, settings)
      end
    end
        
    
    def prepare(value, scope)      
      if required? && value.nil?
        raise ArgumentError, "#{scope.class.name} requires the property #{self.name} to be set"
      end
      
      if not value.nil?
        value = convert!(value, scope)
        validate!(value, scope)
      end
      
      @value = value
    end
    
    def define(klass)
      property = self
      
      scope = klass.instance_variable_get(:"@_smart_properties_method_scope") || begin
        m = Module.new
        klass.send(:include, m)
        klass.instance_variable_set(:"@_smart_properties_method_scope", m)
        m
      end

      scope.send(:attr_reader, name)
      scope.send(:define_method, :"#{name}=") do |value|
        instance_variable_set("@#{property.name}", property.prepare(value, self))
      end
    end

  end
  
  module ClassMethods

    ##
    # Returns the list of smart properties that for this class. This 
    # includes the properties that have been defined in the parent classes.
    #
    # @return [Array<Property>] The list of properties.
    #
    def properties
      @_smart_properties ||= begin        
        parent = if self != SmartProperties
          (ancestors[1..-1].find { |klass| klass.ancestors.include?(SmartProperties) && klass != SmartProperties })
        end
        
        parent ? parent.properties.dup : {}
      end
    end

    ##
    # Defines a new property from a name and a set of options. This results
    # results in creating an accessor that has additional features:
    #
    # 1. Validation of input data by specifiying the +:accepts+ option:
    #    If you use a class as value for this option, the setter will check
    #    if the value it is about to assign is of this type. If you use an
    #    array, the setter will check if the value it is about to assign is
    #    included in this array. Finally, if you specify a block, it will
    #    invoke the block with the value it is about to assign and check if
    #    the block returns a thruthy value, meaning anything but +false+ and
    #    +nil+.
    #
    # 2. Conversion of input data by specifiying the +:converts+ option:
    #    If you use provide a symbol as value for this option, the setter will
    #    invoke this method on the object it is about to assign and take the
    #    result of this call instead. If you provide a block, it will invoke
    #    the block with the value it is about to assign and take the result
    #    of the block instead.
    #
    # 3. Providing a default value by specifiying the +:default+ option.
    #
    # 4. Forcing a property to be present by setting the +:required+ option
    #    to true.
    #
    #
    # @param [Symbol] name the name of the property
    #
    # @param [Hash] options the list of options used to configure the property
    # @option options [Array, Class, Proc] :accepts
    #   specifies how the validation is done
    # @option options [Proc, Symbol] :converts
    #   specifies how the conversion is done
    # @option options :default
    #   specifies the default value of the property
    # @option options [true, false] :required
    #   specifies whether or not this property is required
    #
    # @return [Property] The defined property.
    #
    # @example Definition of a property that makes use of all {SmartProperties} features.
    #
    #  property :language_code, :accepts => [:de, :en],
    #                           :converts => :to_sym,
    #                           :default  => :de,
    #                           :required => true
    #
    def property(name, options = {})
      p = Property.new(name, options)
      p.define(self)

      properties[name] = p
    end
    protected :property

  end
  
  class << self
    
    private
    
      ##
      # Extends the class, which this module is included in, with a property 
      # method to define properties.
      #
      # @param [Class] base the class this module is included in
      #
      def included(base)
        base.extend(ClassMethods)
      end
    
  end
  
  ##
  # Implements a key-value enabled constructor that acts as default
  # constructor for all {SmartProperties}-enabled classes.
  #
  # @param [Hash] attrs the set of attributes that is used for initialization
  #
  def initialize(attrs = {})
    attrs ||= {}

    self.class.properties.each do |_, property|
      value = attrs.key?(property.name) ? attrs.delete(property.name) : property.default(self)
      send(:"#{property.name}=", value)
    end
  end
  
  # TODO: check required

end
