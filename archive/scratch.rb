# A generic cmd class?

class IterableTemplateValue < Hash
  # Note this extending business doesn't work here?
  def initialize(*args, &block)
    @valid_subkeys = nil
    super(*args, &block)
  end
  
  def has_subkey?(key)
    populate_valid_subkeys @valid_subkeys.nil?
    @valid_subkeys.include? key
  end
  
  def populate_valid_subkeys
    @valid_subkeys = self.collect{|k,h| h.keys}.flatten.uniq
  end
  
  def collect_subkey_values(key)
    # Can one directly combine select and combine?
    self.collect{|k,h| h[key]}.select{|v| not v.nil?}
  end
  
  def respond_to?(name)
    super ? true : has_subkey?(name)
  end
  
  def method_missing(name, *args)
    return collect_subkey_values(name) if has_subkey? name
    super
  end
end

# For workflow
# 1. unpack the vars and create a sink for this and then define the output
# 2. define the output paths and insert commands for the creation of directiories
# =>  also want to auto-generate 
# 3. finally match the inputs to any outputs

# also the way to deal with $i.runs.fixed_orig is to have the iterables be
# a special class that is an extension of array

wf = Workflow.new "Anatomical Preprocessing" do  
  vars
  
  cmd "3dSkullStrip -input $head -orig_vol -prefix $brain", :name => :approach1
  
  
  # # Approach 1
  # vars :head => "/path/to/head.nii.gz", :brain => "/path/to/brain.nii.gz"
  # cmd "3dSkullStrip -input $head -orig_vol -prefix $brain", name=:approach1, 
  #   :inputs => {:head => :auto}, 
  #   :outputs => {:brain => :auto}
  # 
  # # Approach 2
  # cmd "3dSkullStrip -input $i.head -orig_vol -prefix $o.brain", name=:approach2, 
  #   :inputs => {:head => "/path/to/head.nii.gz"}, 
  #   :outputs => {:brain => "/path/to/brain.nii.gz"}
  # 
  # # Approach 3
  # vars :head => "/path/to/me", :brain => "/path/to/jack"
  # cmd "3dSkullStrip -input $i.head -orig_vol -prefix $o.brain", name=:approach3
  
  # note name=X if not supplied will auto to 
  # 3dSkullStrip_%03i (%i being the order in which the 3dSkullStrip command was given)
end

def custom_function(input, options = {})
  # do something
  # note: MUST return a hash
  return :output => "#{input}_me.nii.gz"
end

fun :custom_function, input, :key1 => 1, :key2 => "me"
# note that outputs will automatically be determined
# and in this case would be output

# you can remap the output to prevent a name clash
fun :custom_function, input, :key1 => 1, :key2 => "me", 
  :remap_outputs => {:output => :newfile}

  # todo: add name option


# ===   
  

# # should have automated way to convert below class with associated approaches
# # into a command-line script
# run "g-skull-strip afni-anat -i head.nii.gz -o brain.nii.gz -m --other-opts '-dilate 2'"
# # or
# skull_strip :afni_anat, infile: head, outfile: brain, mask: brain_mask


def test
  return :argstr => "-i %s", :position => 2, :jack => 3
end

require 'sourcify'

def test1(me, you=3, options={})
  { :me => me, :you => you, "jack" => options }
end

def test2(me, you, options={})
  return :me => me, :you => you, :options => options
end

def test3(*args, **kwargs)
  print args
  print kwargs
  return 2, 3
end

def test4
  return 2
end

def test5
  me = 2
  if me == 2
    me += 1
  end
  return "me"
end

def test6
  "me"
end

m = :test1
inputs = method(m).parameters # [[:req, :me], [:opt, :you]] # so can check for this in future
innames = inputs.collect{|x| x[1]} 

s = method(m).to_sexp[-1][-1][-1]
s = s[1..-1] if s[0] == :return
puts "bad" if s[0] != "hash"
outnames = s.values_at(*s.each_index.select(&:odd?)).collect{|x| x[1].to_s}


method(:test2).paramaters
ri_for :test2 ? => extract the last line and parse it.

regex_flirt = /
  ^[ ]*
  [-](?<name>\w+)           # Get the option name
  \s+
  (?:\<(?<args>.+)\>)?      # Is there an argument, the name here does not matter
  (?:\{(?<choices>.+)\})?   # What are the choices for the argument, if any
  \s+
  (?:\((?<desc>.+)\))?      # Description for the option
/x

names = regex_flirt.names.collect{|x| x.to_sym}
res = flirt.scan(regex_flirt).collect do |match|
  h = Hash[names.zip(match)]
  h[:argstr]    = "-#{h[:name]}"
  h[:choices]   = h[:choices].split(",") if not h[:choices].nil?
  h[:desc]      = h[:desc].capitalize if not h[:desc].nil?
  if not h[:args].nil?
    args        = h[:args].split("> <").join(", ")
    h[:desc]    = "Takes argument(s): #{args}. #{h[:desc]}"
    nargs       = args.split(", ").count
    h[:argstr] += " " + nargs.times.collect{"%s"}.join(" ")
    if nargs == 1
      h[:type]  = :string
    else
      h[:type]  = :strings
      h[:nargs] = nargs
    end
  end
  h.delete(:args)
  h.delete_if {|k,v| v.nil? }
end


bet = `bet`
regex_bet = /
  ^[ ]*
  [-](?<name>\w+)           # Get the option name
  \s+
  (?:\<(?<args>.+)\>)?      # Is there an argument, the name here does not matter
  (?<desc>.+)?              # Description for the option
/x
names = regex_bet.names.collect{|x| x.to_sym}

res = bet.scan(regex_bet).collect do |match|
  h = Hash[names.zip(match)]
  h[:argstr]    = "-#{h[:name]}"
  h[:desc]      = h[:desc].capitalize if not h[:desc].nil?
  if not h[:args].nil?
    h[:desc]    = "Takes argument(s): #{:args}. #{h[:desc]}"
    nargs       = args.split.count
    h[:argstr] += " " + nargs.times.collect{"%s"}.join(" ")
    if nargs == 1
      h[:type]  = :string
    else
      h[:type]  = :strings
      h[:nargs] = nargs
    end
  end
  h.delete(:args)
  h.delete_if {|k,v| v.nil? }
end


afniskullstrip.split.each do |line|
  
end


class String
  def scan2(regexp)
    names = regexp.names
    scan(regexp).collect do |match|
      Hash[names.zip(match)]
    end
  end
end





def _run_interface(self, runtime):
    """Execute command via subprocess

    Parameters
    ----------
    runtime : passed by the run function

    Returns
    -------
    runtime : updated runtime information

    """
    setattr(runtime, 'stdout', None)
    setattr(runtime, 'stderr', None)
    setattr(runtime, 'cmdline', self.cmdline)
    out_environ = {}
    try:
        display_var = config.get('execution', 'display_variable')
        out_environ = {'DISPLAY': display_var}
    except NoOptionError:
        pass
    iflogger.debug(out_environ)
    if isdefined(self.inputs.environ):
        out_environ.update(self.inputs.environ)
    runtime.environ.update(out_environ)
    if not self._exists_in_path(self.cmd.split()[0]):
        raise IOError("%s could not be found on host %s" % (self.cmd.split()[0],
                                                            runtime.hostname))
    runtime = run_command(runtime)
    if runtime.returncode is None or runtime.returncode != 0:
        self.raise_exception(runtime)

    return runtime

def _exists_in_path(self, cmd):
    '''
    Based on a code snippet from http://orip.org/2009/08/python-checking-if-executable-exists-in.html
    '''

    extensions = os.environ.get("PATHEXT", "").split(os.pathsep)
    for directory in os.environ.get("PATH", "").split(os.pathsep):
        base = os.path.join(directory, cmd)
        options = [base] + [(base + ext) for ext in extensions]
        for filename in options:
            if os.path.exists(filename):
                return True
    return False


def _format_arg(self, name, trait_spec, value):
    """A helper function for _parse_inputs

    Formats a trait containing argstr metadata
    """
    argstr = trait_spec.argstr
    iflogger.debug('%s_%s' %(name, str(value)))
    if trait_spec.is_trait_type(traits.Bool) and "%" not in argstr:
        if value:
            # Boolean options have no format string. Just append options
            # if True.
            return argstr
        else:
            return None
    #traits.Either turns into traits.TraitCompound and does not have any inner_traits
    elif trait_spec.is_trait_type(traits.List) \
    or (trait_spec.is_trait_type(traits.TraitCompound) \
    and isinstance(value, list)):
        # This is a bit simple-minded at present, and should be
        # construed as the default. If more sophisticated behavior
        # is needed, it can be accomplished with metadata (e.g.
        # format string for list member str'ification, specifying
        # the separator, etc.)

        # Depending on whether we stick with traitlets, and whether or
        # not we beef up traitlets.List, we may want to put some
        # type-checking code here as well
        sep = trait_spec.sep
        if sep == None:
            sep = ' '
        if argstr.endswith('...'):

            # repeatable option
            # --id %d... will expand to
            # --id 1 --id 2 --id 3 etc.,.
            argstr = argstr.replace('...', '')
            return sep.join([argstr % elt for elt in value])
        else:
            return argstr % sep.join(str(elt) for elt in value)
    else:
        # Append options using format string.
        return argstr % value

def _parse_inputs(self, skip=None):
    """Parse all inputs using the ``argstr`` format string in the Trait.

    Any inputs that are assigned (not the default_value) are formatted
    to be added to the command line.

    Returns
    -------
    all_args : list
        A list of all inputs formatted for the command line.

    """
    all_args = []
    initial_args = {}
    final_args = {}
    metadata = dict(argstr=lambda t: t is not None)
    for name, spec in sorted(self.inputs.traits(**metadata).items()):
        if skip and name in skip:
            continue
        value = getattr(self.inputs, name)
        if not isdefined(value):
            if spec.genfile:
                value = self._gen_filename(name)
            else:
                continue
        arg = self._format_arg(name, spec, value)
        if arg is None:
            continue
        pos = spec.position
        if pos is not None:
            if pos >= 0:
                initial_args[pos] = arg
            else:
                final_args[pos] = arg
        else:
            all_args.append(arg)
    first_args = [arg for pos, arg in sorted(initial_args.items())]
    last_args = [arg for pos, arg in sorted(final_args.items())]
    return first_args + all_args + last_args


def run(self, **inputs):
    """Execute this interface.

    This interface will not raise an exception if runtime.returncode is
    non-zero.

    Parameters
    ----------
    inputs : allows the interface settings to be updated

    Returns
    -------
    results :  an InterfaceResult object containing a copy of the instance
    that was executed, provenance information and, if successful, results
    """
    self.inputs.set(**inputs)
    self._check_mandatory_inputs()
    interface = self.__class__
    # initialize provenance tracking
    env = deepcopy(os.environ.data)
    runtime = Bunch(cwd=os.getcwd(),
                    returncode=None,
                    duration=None,
                    environ=env,
                    hostname=gethostname())
    t = time()
    try:
        runtime = self._run_interface(runtime)
        runtime.duration = time() - t
        results = InterfaceResult(interface, runtime,
                                  inputs=self.inputs.get_traitsfree())
        results.outputs = self.aggregate_outputs(results.runtime)
    except Exception, e:
        if len(e.args) == 0:
            e.args = ("")

        message = "\nInterface %s failed to run." % self.__class__.__name__

        if config.has_option('logging', 'interface_level') and config.get('logging', 'interface_level').lower() == 'debug':
            inputs_str = "Inputs:" + str(self.inputs) + "\n"
        else:
            inputs_str = ''

        if len(e.args) == 1 and isinstance(e.args[0], str):
            e.args = (e.args[0] + " ".join([message, inputs_str]),)
        else:
            e.args += (message, )
            if inputs_str != '':
                e.args += (inputs_str, )

        #exception raising inhibition for special cases
        if hasattr(self.inputs, 'ignore_exception') and \
        isdefined(self.inputs.ignore_exception) and \
        self.inputs.ignore_exception:
            import traceback
            runtime.traceback = traceback.format_exc()
            runtime.traceback_args = e.args
            return InterfaceResult(interface, runtime)
        else:
            raise
    return results

def run_command(runtime, timeout=0.01):
    """
    Run a command, read stdout and stderr, prefix with timestamp. The returned
    runtime contains a merged stdout+stderr log with timestamps

    http://stackoverflow.com/questions/4984549/merge-and-sync-stdout-and-stderr/5188359#5188359
    """
    PIPE = subprocess.PIPE
    proc = subprocess.Popen(runtime.cmdline,
                             stdout=PIPE,
                             stderr=PIPE,
                             shell=True,
                             cwd=runtime.cwd,
                             env=runtime.environ)
    streams = [
        Stream('stdout', proc.stdout),
        Stream('stderr', proc.stderr)
        ]

    def _process(drain=0):
        try:
            res = select.select(streams, [], [], timeout)
        except select.error, e:
            iflogger.info(str(e))
            if e[0] == errno.EINTR:
                return
            else:
                raise
        else:
            for stream in res[0]:
                stream.read(drain)

    while proc.returncode is None:
        proc.poll()
        _process()
    runtime.returncode = proc.returncode
    _process(drain=1)

    # collect results, merge and return
    result = {}
    temp = []
    for stream in streams:
        rows = stream._rows
        temp += rows
        result[stream._name] = [r[2] for r in rows]
    temp.sort()
    result['merged'] = [r[1] for r in temp]
    runtime.stderr = '\n'.join(result['stderr'])
    runtime.stdout = '\n'.join(result['stdout'])
    runtime.merged = result['merged']
    return runtime
