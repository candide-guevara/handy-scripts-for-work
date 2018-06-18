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

    class prompt (object):
      def py2(self): 
        green = "\033[0;32m"
        reset = "\033[0m"
        return "%s%s@%s >%s\n " % (green, os.environ['USER'], os.path.realpath('.'), reset)
      def __str__(self): 
        green = "\033[0;32m"
        reset = "\033[0m"
        #ps1 = "%s@%s >\n " % (os.environ['USER'], os.path.realpath('.'))
        ps1 = "%s%s@%s >%s\n " % (green, os.environ['USER'], os.path.realpath('.'), reset)
        return ps1

    if sys.version_info.major == 2:
      sys.ps1 = prompt().py2()
    else: #  sys.version_info.major == 3 and sys.version_info.minor <= 5:
      sys.ps1 = prompt()

  except Exception as err:
    print("""
      PAIN AND SUFFERING
      Your nice python shell env got screwed !!
      %r
    """ % err)

if __IS_BBPY__:
  import bas

