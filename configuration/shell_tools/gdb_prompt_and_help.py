#from gdb_common import *

@make_it_safe
def buildprompt (cur_prompt):
  inferior = gdb.selected_inferior()
  program = gdb.current_progspace()
  base_prompt = "--- BAD PROMPT ---"

  if inferior and program and program.filename:
    program_name = program.filename
    exe_name = "%s%s - " % (bldblu, program_name)
    if inferior.pid:
      cur_frame = gdb.selected_frame()
      cur_thread = gdb.selected_thread()
      if cur_thread and cur_thread.ptid:
        thread_id = cur_thread.ptid[1] or cur_thread.ptid[2]
        pid = "%s[%d,%d]" % (bldcyn, inferior.pid, thread_id)
      else:
        pid = "%s[%d]" % (bldcyn, inferior.pid)
      exe_name = "%s%s%s - " % (bldblu, keepLastTwoInPath(program_name), pid)
      if cur_frame:
        pc = hex( cur_frame.pc() ).strip('L')
        sym_line = gdb.find_pc_line(cur_frame.pc())
        if sym_line.symtab:
          src_loc = "%s:%d|%s" % ( keepLastTwoInPath(sym_line.symtab.filename), sym_line.line, pc )
          base_prompt = "%s%s%s" % (exe_name, bldgrn, src_loc)
        else:   
          base_prompt = "%s%s<no_src>|%s" % (exe_name, bldgrn, pc)
      else:
        base_prompt = "%s%s<started>" % (exe_name, bldylw)
    else:
      base_prompt = "%s%s<not_started>" % (exe_name, bldylw)
  else:
    base_prompt = "%s\w - %s<nothing_running>" % (bldblu, bldred)

  base_prompt = "%s%s\n " % (base_prompt, txtrst)
  return add_color(base_prompt)

gdb.prompt_hook = buildprompt
### buildprompt  

@gdb_command
class cheatsheet (gdb.Command):
  """Quick recap of the most common commands."""

  def invoke(self, arg, from_tty):
    myhelp = """Gdb useful commands
    %(cmd)sset args    %(arg)s ARGUMENTS            %(rst)sPass those arguments to the program to debug
    %(cmd)sfile|attach %(arg)sPROGRAM|PID           %(rst)sLoad an executable to debug or attach to the PID process

    %(cmd)sbr        %(arg)sLINE|FUNC|FILE          %(rst)sSet breakpoint 
    %(cmd)sbt|frame  %(arg)s[NUMBER]                %(rst)sPrints stack trace|frame. Corresponding frame is selected
    %(cmd)slist      %(arg)s[LINE|FUNC|ADDR]        %(rst)sPrints the corresponding source code block
    %(cmd)sdisas     %(arg)s[LINE|FUNC|ADDR]        %(rst)sDisassembles the corresponding block
    %(cmd)sx/        %(arg)s[NUMBER][xg|s] ADDR     %(rst)sPrints value at address. x->hex format. g->8-byte word.
    %(cmd)sn|s|si    %(arg)s[NUMBER]                %(rst)sStep OVER | Step INTO source line | assembler instruction.

    %(cmd)sinfo add|sym %(arg)sSYMBOL|ADDRESS       %(rst)sPrints address or source file containing of symbol                  
    %(cmd)sinfo arg|loc|reg%(arg)s                  %(rst)sPrints function args | local variables | hw registers.
    %(cmd)sinfo files%(arg)s                        %(rst)sPrints the address of all elf sections in memory

    %(cmd)shelp user%(arg)s                         %(rst)sLists your custom gdb and python commands
    %(imp)sIMPORTANT : %(rst)sYou may have a hard time with C++ unmangled symbols for some commands (disas, info...)
    """ % { 'cmd' : bldblu, 'arg' : bldcyn, 'imp' : bldylw, 'rst' : txtrst }
    print_color(myhelp)
### END cheatsheet

