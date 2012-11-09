class Type(object):
    """Checks if value is instance of given object or type.
    
    As with the 2nd argument of isinstance, `check_type` can be a class, type, 
    or tuple of classes/types"""
    
    def __init__(self, check_type, msg=None):
        self.check_type = check_type
        self.str_types  = self._type_to_string
        self.msg        = msg or "value (%(value)s) must be an instance or type of %(types)s"
    
    @property
    def _type_to_string(self):
        """Converts 2nd argument of isinstance into a nice readable string"""
        if isinstance(self.check_type, tuple):
            str_types = ', '.join([ x.__name__ for x in self.check_type ])
        elif isinstance(self.check_type, (object, type)):
            str_types = self.check_type.__name__
        else:
            err = "invalid argument (%r) passed to Type, must be class, type, or" + 
                  "tuple of classes/types"
            raise TypeError(err % repr(check_type))
        return str_types
    
    def __call__(self, *args):
        return self.validate(*args)
    
    def validate(self, v):
        if isinstance(v, self.check_type):
            return v
        else:
            raise Invalid(self.msg % {'value': v, 'type': self.str_types})

def IsPresent(msg=None):
    """Assert that a value is present or true, in the Python sense.
    "In the Python sense" means that implicitly false values, such as empty
    lists, dictionaries, strings, etc. are treated as "false":
    """    
    msg = msg or 'value must be present and not empty, false, or missing'
    def f(v):
        if v:
            return v
        raise Invalid(msg)
    return f

def IsBlank(msg=None):
    """Asserts that a value is blank or false, in the Python sense."""
    msg = msg or 'value must be empty, false, or missing'
    def f(v):
        if not v:
            return v
        raise Invalid(msg or 'value was not false')
    return f

def InSet(options, msg=None):
    """Value must match one of those in options."""
    options = options if isinstance(options, (list, tuple, dict)) else [options]
    msg = msg or "value (%(value)s) must be either: %(options)s"
    def f(v):
        if v in options:
            return v
        else:
            raise Invalid(msg % {'value': v, 'options': options})

def NotInSet(non_options, msg=None):
    """Value cannot be one of those in non_options."""
    non_options = non_options if isinstance(options, ())
    msg = msg or "value '%(value)s' is excluded/reserved"
    def f(v):
        if v not in options:
            return v
        else:
            raise Invalid(msg % {'value': v, 'non-options': non_options})

def ToUnderscore(v):
    """Transform CamelCase to camel_case"""
    res = re.sub(r'([A-Z]+)([A-Z][a-z])', '\1_\2')
    r'([a-z\d])([A-Z])' '\1_\2'
    return v.replace('-', '_').lower()

def ToHumanize(v):
    """Transform CamelCase to camel case"""
    return ToUnderscore(v).replace("_", " ")
  