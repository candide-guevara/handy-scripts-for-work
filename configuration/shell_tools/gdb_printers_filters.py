import re, os
#from gdb_common import *

@register_decorator
class SimplifyAndColorDecorator (gdb.FrameDecorator.FrameDecorator):
  EMPTY_BRACKETS = re.compile('<[^<>]*')
  REMOVE_INNER_BRACKETS = re.compile('<[ <>]*>')

  @classmethod
  def removeTemplateArgs (k, name):
    name = k.EMPTY_BRACKETS.sub('<', name)
    name = k.REMOVE_INNER_BRACKETS.sub('<>', name)
    return name
    
  def function (self):
    base_function = self._base.function()
    # We forward the function address so that upper layer can rename it
    if is_int(base_function):
      return base_function

    str_func = SimplifyAndColorDecorator.removeTemplateArgs( safe_to_str(base_function) )
    return add_color(str_func.ljust(24, ' '), bldred)

  def filename (self):
    base_filename = safe_to_str( self._base.filename() )
    return add_color(keepLastTwoInPath(base_filename), txtcyn)

  #def address (self): return None
  def frame_args (self): return None
  def frame_locals (self): return None

### END SimplifyAndColorDecorator

