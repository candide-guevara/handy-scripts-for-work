#! /usr/bin/awk
## This script extract the comments inside shell scripts
## And outputs a formatted text file
# Implemented as a state machine where the state switches
# correspond to patterns and the function to state actions

#################################################################################
### Initialization
#################################################################################

BEGIN {
  # The different states of the program
  STATE_INITIAL = 1;
  STATE_PARSING_GLB = 2;
  STATE_LOOK_FOR_FUNC = 3;
  STATE_PARSING_FUNC = 4;

  # The current state
  STATE = STATE_INITIAL;
  # Only when this flag is set we allow to switch state
  SWITCH_STATE = 1;

  # Arrays in awk are more like dictionaries, this variable ensure we iterate
  # in ascending order all the keys
  PROCINFO["sorted_in"] = "@ind_str_asc";
  # The index of the comment stack
  INDEX_STATE = 0
}

#################################################################################
### Functions
#################################################################################

function titleHeader() {
  if (! FILE_TITLE) {
    printErrorAndDie( \
      "You should pass the file title as a parameter to the awk script");
    exit(1);
  }
  return (bldblu "##################################################################\n" \
          bldblu "### " FILE_TITLE "\n" \
          bldblu "##################################################################\n" \
          txtrst);
}

function funcHeader() {
  sub(/^[[:space:]]*/, "");
  sub(/\).*/, ")");
  return bldgrn "### "$0 txtrst;
}

function dumpCommentStack(header) {
  print (header);
  for (i=0; i<INDEX_STATE; i++) {
    print (" "COMMENT_STACK[i]);
  }
  print("\n");
  INDEX_STATE = 0;
}

# Inside comment lines can be highlighted using * at the start
# to highlighlight a group of words enclose them in __
function pushComment() {
  sub(/^[[:space:]]*## /, "");
  $0 = gensub(/^\*(.*)$/, bldylw "\\1" txtrst, 1);
  $0 = gensub(/__(.+)__/, bldred "\\1" txtrst, "g");
  COMMENT_STACK[INDEX_STATE++] = $0;
}

function printErrorAndDie(error) {
  print(bldred "[ERROR] " error txtrst) > "/dev/stderr";
  exit(1);
}

#################################################################################
### States
#################################################################################

SWITCH_STATE && STATE == STATE_INITIAL {
  SWITCH_STATE = 0;
  if ($0 ~ /^[[:space:]]*## /) {
    STATE = STATE_PARSING_GLB;
    pushComment();
  }
  else if ($0 !~ /^#[[:space:]]*!/) {
    STATE = STATE_LOOK_FOR_FUNC;
    dumpCommentStack(titleHeader());
  }
}

SWITCH_STATE && STATE == STATE_PARSING_GLB {
  SWITCH_STATE = 0;
  if ($0 ~ /^[[:space:]]*## /) {
    pushComment();
  }
  else {
    STATE = STATE_LOOK_FOR_FUNC;
    dumpCommentStack(titleHeader());
  }
}

SWITCH_STATE && STATE == STATE_LOOK_FOR_FUNC && /^[[:space:]]*## / {
  SWITCH_STATE = 0;
  STATE = STATE_PARSING_FUNC;
  pushComment();
}

SWITCH_STATE && STATE == STATE_PARSING_FUNC {
  SWITCH_STATE = 0;
  if ($0 ~ /^[[:space:]]*## /) {
    pushComment();
  }
  else if ($0 ~ /^[[:space:]]*[_[:alnum:]]+[[:space:]]*\(\)[[:space:]]*\{/) {
    STATE = STATE_LOOK_FOR_FUNC;
    dumpCommentStack(funcHeader());
  }
  else if ($0 ~ /^[[:space:]]*function[[:space:]]+[_[:alnum:]]+[[:space:]]*\(\)[[:space:]]*\{/) {
    STATE = STATE_LOOK_FOR_FUNC;
    dumpCommentStack(funcHeader());
  }
  else {
    printErrorAndDie("Could not parse function comment : " $0 ".");
  }
}

{ SWITCH_STATE = 1; }

