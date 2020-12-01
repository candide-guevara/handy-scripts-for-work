## Attempts to fix age of empires sound.
source common.sh || exit 2

set_environment_vars "1017900" AoEDE

patch_visual_studio_runtime_2017
# https://www.protondb.com/app/1017900
rename_game_data_dir_matching Video
echo "ALL DONE"

