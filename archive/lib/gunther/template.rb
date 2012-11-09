class Template  
  REVAR = /
    (?<![\\])         # skip if escaped
    [$]               # indicates this is a variable
      (?:  
        (?:
          ([a-zA-Z][\w\.]*)
          \b
        )
          |
        (?:
          [{][ ]*
            ([a-zA-Z]\S*)
          [ ]*[}]          
        )
      )
  /x
  
  attr_accessor :values
  
  def initialize(options={})
    self.values = options.delete(:values){ {} }
    @backup_values = {}
  end
  
  def fetch(key)
    return values[key.to_sym] if values.has_key? key.to_sym
    return values[key] if values.has_key? key
    raise KeyError, "Could not find #{key} in Template values"
  end
  
  def simple_substitute(template)
    template.gsub(REVAR) do
      key = $1 || $2
      value = fetch(key)
      value
    end
  end
  
  def substitute(template)
    template = template.gsub(REVAR) do
      var = $1 || $2          # $1 for $var; $2 for ${var}
      parts = var.split('.')
      name, calls = parts[0], parts[1..-1]
      
      # There is probably a more efficient way to do this recursion
      name  = substitute(name)
      value = fetch(name)
      value = substitute(value)
      if not calls.empty?
        value = lookup(value, calls)
        value = substitute(value)
      end
      
      value
    end if template.is_a? String
    return template
  end
  
  def compile
    @backup_values = values.clone
    self_substitute(values)
  end
  
  private
    
    def self_substitute(obj)
      obj.each do |key, value|
        value ||= key if obj.is_a? Array
        if value.is_a? Hash or value.is_a? Array
          obj[key] = _self_substitute(value)
        elsif value.is_a? String
          obj[key] = substitute(value)
        end
      end
    end
    
    def lookup(foo0, bars)
      bars.reduce(foo0) do |foo,bar|
        # really needs to be a more efficient way to do this
        foo = substitute(foo)
        bar = substitute(bar)
        
        # binding.pry
        
        # 1. Hash Element
        if foo.is_a? Hash
          next foo[bar.to_sym] if foo.has_key? bar.to_sym
          next foo[bar] if foo.has_key? bar
        end
          
        # 2. Attribute or Method
        next foo.send(bar) if foo.respond_to? bar
        
        # 3. Array or String Slices
        if foo.is_a? Array or foo.is_a? String
          start,stop = bar.split(":")
          stop ||= start
          if start.is_number? and stop.is_number?
            start,stop = start.to_i,stop.to_i
            foos = foo[start..stop]
            next foos if not foos.empty?
          end
        end
            
        # 4. Raise Hell
        full_call = "#{foo0}.#{bars.join('.')}"
        msg = "Lookup of '#{bar}' in '#{foo}' failed (from #{full_call})."
        raise ArgumentError, msg
      end
    end    
end
