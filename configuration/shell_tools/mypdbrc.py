import sys, os, re
import pdb, linecache
import rlcompleter

if sys.version_info[0] > 2:
  raise Exception("TODO: support python 3")

class TermColors:
  bldblk = '\033[1;30m' # Bold Black
  bldred = '\033[1;31m' # Bold Red
  bldgrn = '\033[1;32m' # Bold Green
  bldylw = '\033[1;33m' # Bold Yellow
  bldblu = '\033[1;34m' # Bold Blue
  bldpur = '\033[1;35m' # Bold Purple
  bldcyn = '\033[1;36m' # Bold Cyan
  bldwht = '\033[1;37m' # Bold White
  txtblk = '\033[30m'   # Bold Black
  txtred = '\033[31m'   # Bold Red
  txtgrn = '\033[32m'   # Bold Green
  txtylw = '\033[33m'   # Bold Yellow
  txtblu = '\033[34m'   # Bold Blue
  txtpur = '\033[35m'   # Bold Purple
  txtcyn = '\033[36m'   # Bold Cyan
  txtwht = '\033[37m'   # Bold White
  txtrst = '\033[0m'    # Text Reset


def my_message(debugger, msg):
  print >>debugger.stdout, msg

def my_locals(self, _):
  """ [USER_CUSTOM] prints local and instance variables.
  """
  local_dict = self.curframe.f_locals
  for k in sorted(local_dict.keys()):
    self.message('%s%16s%s : %r' % (TermColors.txtcyn, k, TermColors.txtrst, local_dict[k]))
  if 'self' in local_dict:
    self.message('')
    yours = local_dict['self'].__dict__
    for k in sorted(yours.keys()):
      self.message('%s%16s%s : %r' % (TermColors.txtpur, k, TermColors.txtrst, yours[k]))
  return False


def my_backtrace(self, _):
  """ [USER_CUSTOM] a more colorful and terse backtrace.
  """
  try:
    for frame_lineno in self.stack:
      # TODO if this work OK, monkey patch it into self.print_stack_entry
      my_print_stack_entry(self, frame_lineno)
  except KeyboardInterrupt: pass
  return False

RX_SHORT_PATH = re.compile('^/usr/lib(.+)$')
def my_print_stack_entry(debugger, frame_lineno):
  frame, lineno = frame_lineno
  is_cur = frame is debugger.curframe
  filename = debugger.canonic(frame.f_code.co_filename)
  match = RX_SHORT_PATH.match(filename)
  short_filename = match.group(1) if match else filename

  line = linecache.getline(filename, lineno, frame.f_globals)
  if line:
    line = "\n    " + line.strip()

  frame_str = "%s/%s::%s%s():%d%s%s" % (
      (is_cur and TermColors.bldwht) or TermColors.txtwht,
      short_filename,
      (is_cur and TermColors.bldcyn) or TermColors.txtcyn,
      frame.f_code.co_name or "<lambda>",
      lineno,
      TermColors.txtrst,
      line,
  )
  debugger.message(frame_str)

def _get_cur_file(curframe):
  if '__file__' in curframe.f_globals:
    cur_file = curframe.f_globals['__file__']
  else:
    cur_file = curframe.f_locals['module'].__file__

  cur_file = os.path.normpath( cur_file )
  return cur_file


def __my_bootstrap__(pdb_instance, _):
  """ [USER_CUSTOM] bootstrap code called at pdb init (do not call manually).
  """
  inner_postcmd = pdb_instance.postcmd
  # monkey patching is nasty, we replace postcmd method by a function, we lose self argument
  self = pdb_instance

  # FLAW : filepath update is late by 1 input :-(
  def _mypostcmd(*args, **kwargs):
    self.prompt = '<NO_FILE>'
    lineno = -1
    drop_until = ''
    try:
      self.prompt = _get_cur_file(self.curframe)
      components = self.prompt.split(os.path.sep)
      root_idx = max([0] + [ i for i,v in enumerate(components) if v == drop_until ])
      self.prompt = os.path.sep.join(components[root_idx:])
      lineno = self.curframe.f_lineno
    except: pass

    self.prompt = '%s//%s:%d%s' % (TermColors.bldgrn, self.prompt, lineno, TermColors.txtrst)
    self.message(self.prompt)
    self.prompt = ''
    return inner_postcmd(*args, **kwargs)

  pdb_instance.postcmd = _mypostcmd
  pdb_instance.prompt = '%s%s%s\n ' % (TermColors.bldylw, '### sourced custom pdbrc ###', TermColors.txtrst)
  self.message(pdb_instance.prompt)
  pdb_instance.prompt = ''
  return False


def my_explore(self, _):
  """ [USER_CUSTOM] some debugging for macros.
  """
  curframe = self.curframe
  try:
    self.message('>> curframe')
    self.message("\n".join(sorted(dir(curframe))))
    self.message('>> f_locals')
    self.message("\n".join(sorted(repr(t) for t in curframe.f_locals.items())))
    self.message('>> f_globals')
    self.message("\n".join(sorted(repr(t) for t in curframe.f_globals.items())))
    self.message('>> module')
    self.message("\n".join(sorted(dir(curframe.f_locals['module']))))
  except: pass
  return False


def my_breakpoint(self, location, *args, **kwargs):
  """ [USER_CUSTOM] tries to infer the correct path for a breakpoint
  """
  try:
    is_lineno = False
    try: is_lineno = int(location) > 0
    except: pass
    if not is_lineno:
      cur_dir = os.path.dirname(_get_cur_file(self.curframe))
      location = os.path.join(cur_dir, location)
  except: pass
  return self.do_break(location, *args, **kwargs)


def my_complete(self, text, state):
  if not hasattr(self, 'completer'):
    self.completer = rlcompleter.Completer(self.curframe.f_locals)
  else:
    self.completer.namespace = self.curframe.f_locals
  return self.completer.complete(text, state)


#pdb.Pdb.complete = rlcompleter.Completer(locals()).complete
pdb.Pdb.complete = my_complete

pdb.Pdb.do_mybt = my_backtrace
pdb.Pdb.do_loc = my_locals
pdb.Pdb.do_myb = my_breakpoint
pdb.Pdb.do_exp = my_explore
# only needed for python 2
pdb.Pdb.message = my_message
pdb.Pdb.do___my_bootstrap__ = __my_bootstrap__

