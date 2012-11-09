

# 1. Want to override the Invalid class display of error to be just the 'path' (error in 'path': ...)
# 2. Line 141, change repr(required_keys) => ", ".join(required_keys) or just have it store one key at a time!
# 3. errors.py => InvalidList should return all of the errors!
# 4. Line 130, take out for dictionary value
# 6. Add ToCamelize and ToUnderscore

# X. Consider improving error messages for most validation (ie having the value in them)
#       maybe have Invalid accept unlimited kwrds and use those for string substitution
# X. Write a wrapper that will take *args and pass it to Schema
#       also this would take kwargs and ..
#       specially extract required and default

def test(*args, ***kwrds):
    return [args, kwrds]


import re

class ClassName(object):
    """docstring for ClassName"""
    def __init__(self, arg):
        super(ClassName, self).__init__()
        self.arg = arg

# class method?
add_input(infile, check_type, desc, validations, default=None|value, required=True|False, coerce=True, **trait_settings)



docstring = """
    class Base

    Inputs
    ------
    
    infile : file, length > 1 (required)
        Input image with skull (ie head)
        should be in an appropriate format
    - argstr: '-input %s'
    - position: -1
    - copyfile: False
    - sep: ', '
    - field: outputs.approach

    opt1 : str, choices are '2, 3, 4'
        
    opt2 : int, 3 < value < 10
        Optional 2
    
    
    Outputs
    -------
    
    outfile : file
        Image with skull removed (ie brain)
    - genfile: ${infile.rm_ext}_
        
    mask : file
        Mask indicating what's brain (ie brain mask)
"""


class AfniSkullStrip

    

class Parser(object):
    """This parses the docstring that specifies Schema and Traits to auto-generate"""
    def __init__(self, arg):
        super(Parser, self).__init__()
        self.arg = arg
        

class GenSpec(object):
    """A (auto-)generated input or output spec"""
    spec_types = ["input", "output"]
    
    def __init__(self, spec_type):
        super(GenSpec, self).__init__()
        assert spec_type in spec_types, "Only input or output spec type is allowed"
        self.type   = spec_type
        self.header = spec_type.capitalize() + "s"
        




def extract_spec_docstring(name, doc):
    # Find the start of the block
    # (@ the end of the header)
    header = re.search(r"""     # Note: case is ignored
                ([ ]*)%s        # Save the indent as 1
                [ ]*\n         
                \1(\S)\2{%i}    # Must have matching indentation
                                # followed by non-whitespace characters
                                # that are the same length as 'name'
                """ % (name, len(name)-1), doc, flags=re.X|re.I)
    if not header:
        return None
    start   = header.end()
    indent  = header.group(1)
    nspaces = len(indent)
    
    # Find the end of the block
    # (@ the beginning of the next header or at the end)
    next_header = re.search(r"""
            [ ]{%i}\S+[ ]*\n
            [ ]{%i}\S+[ ]*\n
    """ % (nspaces, nspaces), doc[start:], flags=re.X)
    if next_header:
        end = start + next_header.start()
    else:
        end = len(doc)
    
    # Remove any empty lines
    clean_doc = re.sub(r'^(?:[ ]*\n)', '', doc[start:end], flags=re.M)
    
    return clean_doc
    
doc_inputs = extract_spec_docstring('Inputs', docstring)
#if not doc_inputs: return

# Figure out indentation and stick with that
result = re.search(r"""
    (\s*)
        \w+                     # variable name
            \s*[:]\s*
        [^,\n]+                 # type
            [,]?[ ]*
        [^()\n]*                # validations
        (?:\(\s*(?:.*?)\s*\))?  # required? / defaults            
""", doc_inputs, flags=re.X)
assert result, "Could not figure out indentation in '%s...'" % doc_inputs[0:10]
indent = result.group(1)

# Split options (using indentation)
str_options = re.split(r"^[ ]{%i}(?=\w)" % len(indent), doc_inputs, flags=re.M)
str_options = str_options[1:]

# Remove minimum indentation for clean-up
r = re.compile(r"^[ ]{%i}" % len(indent), flags=re.M)
str_options = [ r.sub('', so) for so in str_options ]

# Parse each option
str_opt = str_options[0]

# Parse 1st line
# var_name : type, validations (required or default X)
#   other
first_line = re.match(r"""
    (\s*)
    (?P<var_name>\w+)                                   # = 'infile'
        \s*[:]\s*
        (?P<type>[^,\n()]+)                             # = 'file'
        [,]?\s*
        (?P<validations>[^()\n]*)                       # = 'length > 1'
        (?:\(\s*(?P<required_or_defaults>.*?)\s*\))?    # = 'required'
""", str_opt, flags=re.X)
opt = first_line.groupdict()
loc = first_line.end()
# convert validations to list
opt['validations'] = re.split(r'\s*,\s*', opt['validations'].strip())
# todo: check when validations is empty

# Parse other stuff (description and additional validations)
result = re.split(r'^[ ]*(\-)[ ]+', str_opt[loc:], flags=re.M)
opt['description']  = ''
opt['arg_settings'] = []
if len(result) == 1 or len(result) > 2:
    desc = result.pop(0).strip()
    desc = re.sub(r'\n\s*', ' ', desc)
    opt['description'] = desc
if result:
    settings = [ x.strip() for i,x in enumerate(result) if i % 2 ]
    settings = '\n'.join(settings)
    try:
        opt['arg_settings'] = yaml.load(settings)
    except yaml.scanner.ScannerError as e:
        raise ArgumentError(
            "Couldn't parse the arg-settings in %s:" % opt['var_name']
            + e.message
        )

    

class TestMe(object):
    @staticmethod
    def test_static(arg):
        print arg
        return arg

    inputs = TestMe.test_static(10)

    @classmethod
    def test_function(self):
        self.me = 2
        print 2

TestMe.test_static(2)
TestMe.test_function()


res = re.search(r'([ ]*)(\w+)[ ]*[:][ ]*(.+?)(?:\((.+?)\))[ ]*\n[ ]*(.*)', inputs)
indent,variable,settings,reqs = res.groups()

# inputs, split if two \ns or if \w\n(---

class Base:
    """
    
    Inputs
    ------
    
    infile : file, length >2 (required)
        Input image with skull
        * can be blank
        * can be empty
        * must be between 2 and 4
        * must be greater than 2
        * must be less than 4
        * must match /pattern/
        * must have length less than 2
        * must have length greater than 2
        * must have length between 2 and 4
        * must be either 'one', 'two', or 'three'
        * must not be 'four' or 'five'
        * will substitute /pattern/ for replace
        * will clamp to have min=2 and max=3
        * will lower case
        * will upper case
        * will capitalize
        * will title case
        * will underscore
        * will humanize
    me : file, length
        
    
    Outputs
    -------
    
    outfile : file
        Brain image with skull removed
    
    mask : file
        Mask indicating voxels that are brain
    
    add_input :infile, "Input image with skull", :required => true, :type => :pathname
    add_output :outfile, "Image with skull removed", :type => :pathname
    add_output :mask, "Simple mask of what's brain", :type => :pathname
    
    
    infile : int, is_file, 
        type: int
        is_file: True
    
    
    
    """
    
class AfniSkullStrip(Base):
    """
    
    Inputs
    -----
    ....
    
    """

afni = AfniSkullStrip()
afni.inputs
    
    
    
    with add_input as i:
        i.subject(coerce=True, type=int, required=True, is_file=True, length=(2,5))
        
        
        i.desc      = "description"
        i.required  = True
        i.checkpath = True
        i.short     = "i"
    
    # short="i"?
    add_input("subject", 
                Coerce(int), 
                Type(int), 
                ranger(min=, ), 
                length(min=..), 
                )
    
    add_input("subject", coerce=True, type=int, required=True, sub=("me", "you")
                exclusion = d(in=[1,2,3], 'message': 'subject must ... %(value)s'), 
                exclusion = {'in': [1,2,3]}), in_range = (None, 2)
                
                ConvertTo = int, Type = int

    convert_to(int)
    type_is(int)
    
    Convert(int)
    Type(int)
    
    Choices()
    Exclusions()
    
    coerce  = something_calleable
    type    = of_this_type # can have Or() And(None, Int)
    
    # other validations    
        # for error messages allow %(value)s to express the value and %(key)s for ...
    exclusion = {'in': [], 'message' } # value is excluded/reserved
    format = {'with': /sv/, 'message': } # is invalid
    inclusion = {"in": [1,2,3], 'message': }
    
    length = {'min': 2 | 'max': 3 | 'in': 1:4 | 'is': | 'too_long': | 'too_short' | 'wrong_length'}
        # %(count)s
        # tokenizer or something like this to alter the counting (or what is counted) ...
    
    numericality = {
        'greater_than' | '>':     # must be greater than %(count)s
        'greater_than_or_equal_to' | '>=' | '=>':     # must be greater than or equal to %(count)s
        'equal_to' | '==':  # must be equal to %(count)s
        'less_than' | '<': # must be less than %(count)s
        'less_than_or_equal_to' | '<=' | '=<':  # must be less than or equal to %(count)s
    }
    # message
    
    path = :exists => true
    
    required = true
    
    if or unless => function or string that evaluated
    
    # can have with if ... 
    
    validates => ...
    
    # custom validation
    
    
    {"min": }

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
