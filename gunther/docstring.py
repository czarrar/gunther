import re
import yaml

docstring = """
    Testing

    Inputs
    ------
    
    infile : filepath, length > 1 (required)
        Input image with skull (ie head)
        should be in an appropriate format
        ===
        - argstr: '-input %s'
        - position: -1
        - copyfile: False
        - sep: ', '
        - field: outputs.approach
    
    opt1 : str, choices are '2, 3, 4'
        Must have a description!
    
    opt2 : int, 3 < value < 10
        Testing option
        ===
        - argstr: '%i'
        - position: 0
    
    
    Outputs
    -------
    
    outfile : filepath
        Image with skull removed (ie brain)
        ===
        - genfile: ${infile.rm_ext}_brain.nii.gz
        
    mask : filepath
        Mask indicating what's brain (ie brain mask)
        ===
        - genfile: ${infile.rm_ext}_mask.nii.gz
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

def split_options(doc_spec):
    """Splits the different inputs or outputs. Returns a list."""
    # Figure out indentation and stick with that
    re_indent = re.search(r"""
        (\s*)
            \w+                     # variable name
                \s*[:]\s*
            [^,\n]+                 # type          
    """, doc_spec, flags=re.X)
    assert re_indent, "Could not figure out indentation in '%s...'" % doc_spec[0:10]
    indent = re_indent.group(1)
    
    # Split options (using indentation)
    str_options = re.split(r"^[ ]{%i}(?=\w)" % len(indent), doc_spec, flags=re.M)
    str_options = str_options[1:]
    
    # Remove minimum indentation for clean-up
    r = re.compile(r"^[ ]{%i}" % len(indent), flags=re.M)
    str_options = [ r.sub('', so) for so in str_options ]
    
    return str_options

def parse_option(str_opt):
    """Parses one input or output option. Returns a dict."""
    # Split based on ===
    # so seperate out trait settings if given
    split = re.split(r'\n\s+===\s*\n', str_opt)
    trait_settings = split.pop(1) if len(split) == 2 else {}
    other_details = split[0]
    
    # Go back and parse first couple of lines
    # var_name : type, validations (required or default X)
    #      description
    parse_other_details = re.match(r"""
        (?P<var_name>\w+)                                   # = 'infile'
            \s*[:]\s*
            (?P<type>[^,\n()]+)                             # = 'file'
            [,]?\s*
            (?P<validations>[^()\n]*)                       # = 'length > 1'
            (?:\(\s*(?P<required_or_defaults>[^()\n]*?)\s*\))?    # = 'required'
            \n\s+(?P<description>.+)\s*
    """, other_details, flags=re.X|re.S)
    if not parse_other_details:
        raise Exception('Unable to parse: %s...' % other_details[0:10])
    opt = parse_other_details.groupdict()
    
    # Convert validations to list
    opt['validations'] = re.split(r'\s*,\s*', opt['validations'].strip())
    if not opt['validations'][0]: opt['validations'] = []
    
    # For trait settings
    if trait_settings:
        # remove list element '-'
        re.sub(r'^\s+\-[ ]', '', trait_settings)
        # parse as yaml
        try:
            trait_settings = yaml.load(trait_settings)
        except yaml.scanner.ScannerError as e:
            raise ArgumentError(
                "Couldn't parse the arg-settings in %s:" % opt['var_name']
                + e.message
            )
    opt['trait_settings'] = trait_settings
    
    return opt

def parse_spec(spec_name, doc_string):
    """Parses the doc string for either an input or output spec."""
    doc_spec = extract_spec_docstring(spec_name, doc_string)
    if not doc_spec: return None
    str_options = split_options(doc_spec)
    spec_opts = [ parse_option(str_opt) for str_opt in str_options ]
    return spec_opts

dict_input_spec = parse_spec('Inputs', docstring)
dict_output_spec = parse_spec('Outputs', docstring)


# Type
eval()
