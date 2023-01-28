#! /usr/bin/awk
## This scripts contains color code definitions. Source it to
## use colors in other awk scripts.

BEGIN {
  escape=sprintf("%c", 27);
  txtblk=gensub(/\\e/, escape, 1, ENVIRON["txtblk"]);   # Black
  txtred=gensub(/\\e/, escape, 1, ENVIRON["txtred"]);   # Red
  txtgrn=gensub(/\\e/, escape, 1, ENVIRON["txtgrn"]);   # Green
  txtylw=gensub(/\\e/, escape, 1, ENVIRON["txtylw"]);   # Yellow
  txtblu=gensub(/\\e/, escape, 1, ENVIRON["txtblu"]);   # Blue
  txtpur=gensub(/\\e/, escape, 1, ENVIRON["txtpur"]);   # Purple
  txtcyn=gensub(/\\e/, escape, 1, ENVIRON["txtcyn"]);   # Cyan
  txtwht=gensub(/\\e/, escape, 1, ENVIRON["txtwht"]);   # White
  txtgry=gensub(/\\e/, escape, 1, ENVIRON["txtgry"]);   # Grey
  bldblk=gensub(/\\e/, escape, 1, ENVIRON["bldblk"]);   # Bold Black
  bldred=gensub(/\\e/, escape, 1, ENVIRON["bldred"]);   # Bold Red
  bldgrn=gensub(/\\e/, escape, 1, ENVIRON["bldgrn"]);   # Bold Green
  bldylw=gensub(/\\e/, escape, 1, ENVIRON["bldylw"]);   # Bold Yellow
  bldblu=gensub(/\\e/, escape, 1, ENVIRON["bldblu"]);   # Bold Blue
  bldpur=gensub(/\\e/, escape, 1, ENVIRON["bldpur"]);   # Bold Purple
  bldcyn=gensub(/\\e/, escape, 1, ENVIRON["bldcyn"]);   # Bold Cyan
  bldwht=gensub(/\\e/, escape, 1, ENVIRON["bldwht"]);   # Bold White
  bldgry=gensub(/\\e/, escape, 1, ENVIRON["bldgry"]);   # Bold Grey
  bkgred=gensub(/\\e/, escape, 1, ENVIRON["bkgred"]);   # Background Red
  bkggrn=gensub(/\\e/, escape, 1, ENVIRON["bkggrn"]);   # Background Green
  bkgylw=gensub(/\\e/, escape, 1, ENVIRON["bkgylw"]);   # Background Yellow
  bkgblu=gensub(/\\e/, escape, 1, ENVIRON["bkgblu"]);   # Background Blue
  bkgpur=gensub(/\\e/, escape, 1, ENVIRON["bkgpur"]);   # Background Purple
  bkgcyn=gensub(/\\e/, escape, 1, ENVIRON["bkgcyn"]);   # Background Cyan
  bkgwht=gensub(/\\e/, escape, 1, ENVIRON["bkgwht"]);   # Background White
  txtrst=gensub(/\\e/, escape, 1, ENVIRON["txtrst"]);   # Text Reset
}

