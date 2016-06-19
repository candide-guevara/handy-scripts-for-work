import os, sys

try:
  __IPYTHON__ = __IPYTHON__
except:
  __IPYTHON__ = False

try:
  __IS_BBPY__ = '_BBPY_ENVIRON' in globals()
except:
  __IS_BBPY__ = False

if not __IPYTHON__:
  try:
    import readline
    import rlcompleter
    readline.parse_and_bind("tab: complete")
  except ImportError:
    pass
  
  try:
    green = "\033[0;32m"
    reset = "\033[0m"
    sys.ps1 = "%s%s@%s >%s\n  " % (green, os.environ['USER'], os.path.realpath('.'), reset)
    del green, reset
  except:
    pass

if __IS_BBPY__:
  import bas

