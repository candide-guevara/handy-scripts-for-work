## Attempts to fix age of empires sound.
source common.sh || exit 2

set_environment_vars "1017900" AoEDE

patch_visual_studio_runtime_2017
# https://www.protondb.com/app/1017900
# gives warning and does not fix sh*t
# WINEDLLOVERRIDES="xaudio2_7=b,n" does not do sh*t
#rename_game_data_dir_matching Video
echo "ALL DONE"

