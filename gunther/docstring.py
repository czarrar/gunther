import re

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

