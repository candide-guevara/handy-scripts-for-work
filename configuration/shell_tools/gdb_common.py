import sys, string, itertools
import gdb.printing

bldblk = '\[\e[1;30m\]' # Bold Black
bldred = '\[\e[1;31m\]' # Bold Red
bldgrn = '\[\e[1;32m\]' # Bold Green
bldylw = '\[\e[1;33m\]' # Bold Yellow
bldblu = '\[\e[1;34m\]' # Bold Blue
bldpur = '\[\e[1;35m\]' # Bold Purple
bldcyn = '\[\e[1;36m\]' # Bold Cyan
bldwht = '\[\e[1;37m\]' # Bold White
txtblk = '\[\e[30m\]' # Bold Black
txtred = '\[\e[31m\]' # Bold Red
txtgrn = '\[\e[32m\]' # Bold Green
txtylw = '\[\e[33m\]' # Bold Yellow
txtblu = '\[\e[34m\]' # Bold Blue
txtpur = '\[\e[35m\]' # Bold Purple
txtcyn = '\[\e[36m\]' # Bold Cyan
txtwht = '\[\e[37m\]' # Bold White
txtrst = '\[\e[0m\]'    # Text Reset
BASE_16 = '0123456789abcdef'

def intToAscii(i):
  if (chr(i) in string.whitespace): return ' '
  elif (chr(i) in string.printable): return repr(chr(i))[1:-1]
  else: return '.'


def add_color(message, color=None):
  if color:
    return gdb.prompt.substitute_prompt( "%s%s%s" % (color, message, txtrst) )
  return gdb.prompt.substitute_prompt( message )

def print_color(message, color=None):
  print( add_color(message, color) )

def keepLastTwoInPath (filepath):
  dirs,name = os.path.split(filepath)
  if dirs: return os.path.basename(dirs) + '/' + name
  else: return name

def is_int (obj):
  if sys.version_info[0] == 3:
    if isinstance(obj, int): return True
  else:
    if isinstance(obj, (int,long)): return True
  return False

def safe_to_str (obj):
  if sys.version_info[0] == 3:
    if isinstance(obj, str): return obj
    if isinstance(obj, int): return hex(obj)
  else:
    if isinstance(obj, basestring): return obj
    if isinstance(obj, (int,long)): return hex(obj)
  return "??"

def make_it_safe (function):
  def safe_function(*args):
    try:
      return function(*args)
    except:
      error = "\n".join( repr(v) for v in sys.exc_info() )
      print_color( "[ERROR] : Something went bad while executing %r : %r" % (function, error), bldred )
      return None
  return safe_function    

def gdb_command (klass):
  klass (klass.__name__, gdb.COMMAND_USER)
  return klass

def register_printer_for_rx (pattern_list):
  if not gdb.pretty_printers:
    rx_to_printer = gdb.printing.RegexpCollectionPrettyPrinter("global_pretty_printers")
    gdb.pretty_printers.append(rx_to_printer)

  def inner_register (klass):
    rx_to_printer = gdb.pretty_printers[0]
    for pattern in pattern_list:
      rx_to_printer.add_printer(klass.__name__, pattern, klass)
    return klass
  return inner_register  

def register_frame_filter (klass):
  frame_filter = klass()
  frame_filter.name = klass.__name__
  frame_filter.enabled = True
  frame_filter.priority = 100
  gdb.frame_filters[frame_filter.name] = frame_filter
  return klass

def register_decorator (klass):
  class NoFilter (object):
    def filter (self, frame_it):
      if sys.version_info[0] == 3:
          return map(klass, frame_it)
      else:  
        return itertools.imap(klass, frame_it)
  register_frame_filter(NoFilter)
  return klass

@gdb_command
class undo_all_custom (gdb.Command):
  """Removes all custom for prompt, frame filters and pretty printers"""

  def invoke (self, arg, from_tty):
    gdb.pretty_printers = []
    gdb.frame_filters = {}
    gdb.prompt_hook = lambda p : "--------- GDB ----------\n "

### END undo_all_custom

@gdb_command
class rerun (gdb.Command):
  """Kills current inferior, deletes all breakpoints, reloads binary, adds new breakpoint and reruns the exe.
  [USAGE] rerun BREAKPT_DESC
  """

  def invoke (self, brpt_desc, from_tty):
    exepath = gdb.current_progspace().filename
    gdb.execute('kill', from_tty=False)
    gdb.execute('delete breakpoints', from_tty=False)
    gdb.execute('file ' + exepath, from_tty=False)
    if brpt_desc:
      gdb.execute('break ' + brpt_desc, from_tty=False)
    gdb.execute('run', from_tty=False)
    gdb.execute('list', from_tty=False)
    gdb.execute('backtrace 5', from_tty=False)

  def complete (self, text, word):
    return gdb.COMPLETE_LOCATION

### END rerun

@gdb_command
class info_all_hex (gdb.Command):
  """Prints information from different sources, integers are in hexadecimal format
  [USAGE] info_all_hex
  """

  def invoke (self, brpt_desc, from_tty):
    try:
      gdb.execute('set output-radix 16', from_tty=False)
      gdb.execute('info args', from_tty=False)
      gdb.execute('info locals', from_tty=False)
    finally:
      gdb.execute('set output-radix 10', from_tty=False)

### END info_all_hex

@gdb_command
class hexdump (gdb.Command):
  """Displays program memory in canonical format.
  [USAGE] hexdump HEX_ADDR DECIMAL_LEN
  """
  HEXDUMP_LINE = 16
  INT_TO_HEX = [ BASE_16[int(i / 16)] + BASE_16[i % 16] for i in range(0, 256) ] + ["  "]
  INT_TO_ASCII = [ intToAscii(i) for i in range(0, 256) ] + [""]

  def invoke (self, arg, from_tty):
    addr, len = arg.split(" ")
    print( self.internal_hexdump(int(addr,16), int(len)) )

  def internal_hexdump(self, addr, byte_len):
    byteBuffer = gdb.selected_inferior().read_memory(addr, byte_len)
    lines = []
    lenBuf = len(byteBuffer)

    for i in range(0, lenBuf, hexdump.HEXDUMP_LINE):
      hexPart, asciiPart = ([], [])
      lineLen = i + hexdump.HEXDUMP_LINE
      halfLen = i + int(hexdump.HEXDUMP_LINE / 2)

      for j in range(i, lineLen):
        index = 256
        if (j < lenBuf): index = ord(byteBuffer[j])
        if (j == halfLen): hexPart.append("")

        hexPart.append(hexdump.INT_TO_HEX[index])
        asciiPart.append(hexdump.INT_TO_ASCII[index])

      hexLine = " ".join(hexPart)
      asciiLine = "|" + "".join(asciiPart) + "|"
      address = "{0:08X}".format(i)
      lines.append(address + "  " + hexLine + "  " + asciiLine)
    return "\n".join(lines)
### END hexdump

