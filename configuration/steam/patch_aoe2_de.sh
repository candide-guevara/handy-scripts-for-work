## Attempts to fix age of empires 2 multiplayer.
source common.sh || exit 2

set_environment_vars "813780" AoE2DE

patch_visual_studio_runtime_2019
# https://www.reddit.com/r/aoe2/comments/dwuplr/how_to_run_age_of_empires_2_definitive_edition_on/
rename_game_data_dir_matching movies 
echo "ALL DONE"

