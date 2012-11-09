class Array
  # Borrowed from rails
  
  # Equal to <tt>self[1]</tt>.
  #
  #   %w( a b c d e).second # => "b"
  def second
    self[1]
  end

  # Equal to <tt>self[2]</tt>.
  #
  #   %w( a b c d e).third # => "c"
  def third
    self[2]
  end

  # Equal to <tt>self[3]</tt>.
  #
  #   %w( a b c d e).fourth # => "d"
  def fourth
    self[3]
  end

  # Equal to <tt>self[4]</tt>.
  #
  #   %w( a b c d e).fifth # => "e"
  def fifth
    self[4]
  end

  # Equal to <tt>self[41]</tt>. Also known as accessing "the reddit".
  def forty_two
    self[41]
  end
end

class String
  # Can I use super instead of these aliases?
  alias_method :orig_method_missing, :method_missing
  alias_method :orig_respond_to?, :respond_to?
  
  # TODO: restrict the Pathname functions supported here! with forwardable?
  
  def is_number?
    true if Float(self) rescue false
  end
  
  def to_p
    Pathname.new(self)
  end
  
  def to_file(path)
    f = File.new(path, "w")
    f.write(self)
    f.close
  end
  
  def respond_to?(name)
    orig_respond_to?(name) ? true : Pathname.method_defined?(name)
  end
  
  def method_missing(name, *args)
    return Pathname.new(self).send(name, *args).to_s if Pathname.method_defined? name
    orig_method_missing(name, *args)
  end

  # Below code was borrowed from rails active-support and spectacles
  def camelize(this_camel_is_capital = true)
    if this_camel_is_capital
      gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    else
      self.first + camelize[1..-1]
    end
  end
  
  def underscore
    gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
  
  def humanize
    underscore.tr("_", " ")
  end
end


class Symbol
  # Below code was borrowed from the spectacles project
  def camelize
    to_s.camelize.to_sym
  end
  
  def underscore
    to_s.underscore.to_sym
  end
end


class Pathname
  # Can I use super instead of these aliases?
  alias_method :orig_sub_ext, :sub_ext
  
  def sub_ext(p1)
    self.sub(/((\.gz)|(\.bz2))$/, "").orig_sub_ext(p1)
  end
  
  def rm_ext
    self.sub_ext("")
  end  
end
