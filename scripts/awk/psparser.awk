#! /usr/bin/awk
## This script extract color the output of ps.

{
  # This will only work with the `-f` option for full listing.
  user = $1;
  pid = $2;
  ppid = $3;
  cpu_usage = $4;
  start_time = $5;
  tty = $6;
  cpu_time = $7;
  command = $8;

  $1 = $2 = $3 = $4 = $5 = $6 = $7 = $8 = "";
  gsub(/^\s*/, "");

  # "\t" cpu_usage \
  # " " start_time \
  # " " tty \
  # " " cpu_time \
  print(sprintf("%-16s", user) \
           txtylw sprintf("%-6s", pid) \
           txtrst sprintf("%-6s", ppid) \
           bldcyn command \
           txtgry " " $0 txtrst);
}

