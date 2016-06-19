'''
Created on Mar 23, 2013
Some util methods shared by all home python scripts.
@author: cguevara
'''
import shutil, subprocess, os, string, sys, re, shlex

BASE_16 = '0123456789abcdef'
def __intToAscii__(i):
  if (chr(i) in string.whitespace): return ' '
  elif (chr(i) in string.printable): return repr(chr(i))[1:-1]
  else: return '.'

INT_TO_HEX = [ BASE_16[int(i / 16)] + BASE_16[i % 16]
              for i in range(0, 256)] + ["  "]
INT_TO_ASCII = [ __intToAscii__(i) for i in range(0, 256)] + [""]

class MyUtils(object):
  logger = None
  HEXDUMP_LINE = 16
  toOldFormat = re.compile(r"\{([^}]+)\}")
  toSimpleOldFormat = re.compile(r"\{\}")

  @staticmethod
  def __static_init__(**args):
    if ('logger' in args):
      MyUtils.logger = args['logger']

  @staticmethod
  def hexdump(byteBuffer):
    lines = []
    lenBuf = len(byteBuffer)

    for i in range(0, lenBuf, MyUtils.HEXDUMP_LINE):
      hexPart, asciiPart = ([], [])
      lineLen = i + MyUtils.HEXDUMP_LINE
      halfLen = i + int(MyUtils.HEXDUMP_LINE / 2)

      for j in range(i, lineLen):
        index = 256
        if (j < lenBuf): index = ord(byteBuffer[j])
        if (j == halfLen): hexPart.append("")

        hexPart.append(INT_TO_HEX[index])
        asciiPart.append(INT_TO_ASCII[index])

      hexLine = " ".join(hexPart)
      asciiLine = "|" + "".join(asciiPart) + "|"
      address = "{0:08X}".format(i)
      lines.append(address + "  " + hexLine + "  " + asciiLine)
    return "\n".join(lines)

  @staticmethod
  def format(strToFormat, *vars, **namedArgs):
    if sys.version_info < (3, 0):
      if (MyUtils.toSimpleOldFormat.search(strToFormat)):
        strToFormat = MyUtils.toSimpleOldFormat.subn(r"%s", strToFormat)[0]
        strToFormat = strToFormat % vars
      else:
        strToFormat = MyUtils.toOldFormat.subn(r"%(\1)s", strToFormat)[0]
        strToFormat = strToFormat % namedArgs
      return strToFormat
    else:
      if (not namedArgs):
        return strToFormat.format(*vars)
      else: return strToFormat.format(**namedArgs)

  @staticmethod
  def launchCommand(command, stdout = None):
    concatCommand = ' '.join(command)
    command = shlex.split(concatCommand)
    MyUtils.logger.info('Running %s \nRedirecting to %s', concatCommand, str(stdout))

    try:
      returnCode = subprocess.call(command, stdout = stdout)
      if (returnCode):
        raise Exception(command[0] + " returned with errors " + str(returnCode))
    except Exception:
      shellError = sys.exc_info()[1]
      MyUtils.logger.warn('Command failed : %s', str(shellError))
      raise shellError

  @staticmethod
  def chunkIt (iterable, size):
    chunk = []
    for item in iterable:
      chunk.append(item)
      if ( len(chunk) == size ):
        yield chunk
        chunk = []
    if (chunk): yield chunk    

  @staticmethod
  def cleanDirectory (dirname):
    MyUtils.logger.info("Deleting everything inside %s", dirname)
    if (not os.path.isdir(dirname)):
      os.makedirs(dirname)
    else:
      def deleteItem(name): 
        path = os.path.join(dirname, name) 
        if (os.path.isdir(path)): shutil.rmtree( path )
        else: os.remove(path)
      map(deleteItem, os.listdir(dirname))

  @staticmethod
  def mkdir (dirname):
    if (not os.path.isdir(dirname)):
      os.makedirs(dirname)

# ## END MyUtils

