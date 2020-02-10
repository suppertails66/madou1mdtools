


make libmd
make madou1md_decmp
make madou1md_decmppack
make grpdmp_md
make grpunmap

#mkdir -p testout
mkdir -p rsrc_raw/decmp
mkdir -p rsrc/orig/grp


# # compile logo
# ./madou1md_decmppack madou1.md 0x92b9a testout/compile_logo- --bigblocks
# 
# # carbuncle gao
# #./madou1md_decmppack madou1.md 0x92bb4 testout/carbuncle_intro- --bigblocks
# 
# title screen
# subheaders begin at 0xd00b2
./madou1md_decmppack madou1.md 0x92bc8 rsrc_raw/decmp/title- --bigblocks
./madou1md_decmppack madou1.md 0x92bc8 rsrc_raw/decmp/title- --bigblocks --asvram

# cutscene borders
#./madou1md_decmppack madou1.md 0x8d32c rsrc_raw/decmp/test- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x8d33a rsrc_raw/decmp/intro_pokan- --bigblocks
./madou1md_decmppack madou1.md 0x8d33a rsrc_raw/decmp/intro_pokan- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x8d3e2 rsrc_raw/decmp/intro_doki- --bigblocks
./madou1md_decmppack madou1.md 0x8d3e2 rsrc_raw/decmp/intro_doki- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x8d432 rsrc_raw/decmp/intro_final- --bigblocks
./madou1md_decmppack madou1.md 0x8d432 rsrc_raw/decmp/intro_final- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x77ED2 rsrc_raw/decmp/bayoen_name- --bigblocks
./madou1md_decmppack madou1.md 0x77ED2 rsrc_raw/decmp/bayoen_name- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x7610E rsrc_raw/decmp/panotty_main- --bigblocks

./madou1md_decmppack madou1.md 0x76116 rsrc_raw/decmp/panotty_wah- --bigblocks

./madou1md_decmppack madou1.md 0x92b9a rsrc_raw/decmp/compile_logo- --bigblocks

./madou1md_decmppack madou1.md 0x780C8 rsrc_raw/decmp/battle_main- --bigblocks

./madou1md_decmppack madou1.md 0x7608E rsrc_raw/decmp/mrflea- --bigblocks

./madou1md_decmppack madou1.md 0x788AA rsrc_raw/decmp/panotty_amigo_main_all- --bigblocks

./madou1md_decmppack madou1.md 0x788B8 rsrc_raw/decmp/panotty_amigo_main- --bigblocks

./madou1md_decmppack madou1.md 0x788C0 rsrc_raw/decmp/panotty_amigo_wah- --bigblocks

./madou1md_decmppack madou1.md 0x78838 rsrc_raw/decmp/mrflea_amigo- --bigblocks

./madou1md_decmppack madou1.md 0x7857C rsrc_raw/decmp/timer- --bigblocks

./madou1md_decmppack madou1.md 0x8A12C rsrc_raw/decmp/karaoke- --bigblocks

./madou1md_decmppack madou1.md 0x2710C rsrc_raw/decmp/cockadoodle- --bigblocks

./madou1md_decmppack madou1.md 0x75FEE rsrc_raw/decmp/demon_escape- --bigblocks

./madou1md_decmppack madou1.md 0x78534 rsrc_raw/decmp/escape_doors- --bigblocks

./madou1md_decmppack madou1.md 0x961A6 rsrc_raw/decmp/examscore- --bigblocks
./madou1md_decmppack madou1.md 0x961A6 rsrc_raw/decmp/examscore- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x961C0 rsrc_raw/decmp/badend- --bigblocks
./madou1md_decmppack madou1.md 0x961C0 rsrc_raw/decmp/badend- --bigblocks --asvram

./madou1md_decmppack madou1.md 0x9DF7E rsrc_raw/decmp/credits0- --bigblocks
./madou1md_decmppack madou1.md 0x9DF9E rsrc_raw/decmp/credits1- --bigblocks
./madou1md_decmppack madou1.md 0x9DFBE rsrc_raw/decmp/credits2- --bigblocks
./madou1md_decmppack madou1.md 0x9DFF2 rsrc_raw/decmp/credits3- --bigblocks
./madou1md_decmppack madou1.md 0x9E020 rsrc_raw/decmp/credits4- --bigblocks
./madou1md_decmppack madou1.md 0x9E040 rsrc_raw/decmp/credits5- --bigblocks
./madou1md_decmppack madou1.md 0x9E054 rsrc_raw/decmp/credits6- --bigblocks
./madou1md_decmppack madou1.md 0x9E06E rsrc_raw/decmp/credits7- --bigblocks
./madou1md_decmppack madou1.md 0x9E088 rsrc_raw/decmp/credits8- --bigblocks
./madou1md_decmppack madou1.md 0x9E096 rsrc_raw/decmp/credits9- --bigblocks

./madou1md_decmppack madou1.md 0x7601E rsrc_raw/decmp/skeletont- --bigblocks

 rm -r rsrc_raw/decmp/test-*
# ./madou1md_decmppack madou1.md 0x9E0D0 rsrc_raw/decmp/test- --bigblocks
./madou1md_decmppack madou1.md 0x77FAE rsrc_raw/decmp/test- --bigblocks

#./madou1md_decmppack madou1.md 0x9DF7E rsrc_raw/decmp/test- --bigblocks
#./madou1md_decmppack madou1.md 0x9DF9E rsrc_raw/decmp/test- --bigblocks
#./madou1md_decmppack madou1.md 0x9DFBE rsrc_raw/decmp/test- --bigblocks

#./madou1md_decmppack madou1.md 0x81616 rsrc_raw/decmp/test- --bigblocks

# dungeon interface
#./madou1md_decmppack madou1.md 0x7802e testout/dungeon-hud- --bigblocks

#./madou1md_decmppack madou1.md 0x78136 testout/test- --bigblocks

#./madou1md_decmppack madou1.md 0x77E64 testout/test- --bigblocks

# empty item?
#./madou1md_decmp madou1.md 0xb8066 testout/test.bin --bigblocks
#./madou1md_decmp madou1.md 0x1f00f8 testout/test.bin --bigblocks

for file in rsrc_raw/decmp/*.bin; do
  ./grpdmp_md $file $(dirname $file)/$(basename $file .bin).png
done;

for file in rsrc_raw/decmp/credits*.bin; do
  ./grpdmp_md $file $(dirname $file)/$(basename $file .bin).png -p rsrc_raw/pal/credits.bin
done;

./grpunmap rsrc_raw/decmp/title-vram.bin rsrc_raw/decmp/title-4-0xC000.bin 64 64 rsrc/orig/grp/title_main.png -p rsrc_raw/pal/title.bin
./grpunmap rsrc_raw/decmp/title-vram.bin rsrc_raw/decmp/title-5-0xE000.bin 64 64 rsrc/orig/grp/title_sub.png -p rsrc_raw/pal/title.bin

./grpunmap rsrc_raw/decmp/intro_pokan-vram.bin rsrc_raw/decmp/intro_pokan-0-0xE000.bin 64 17 rsrc/orig/grp/intro_pokan.png -p rsrc_raw/pal/intro_pokan.bin

./grpunmap rsrc_raw/decmp/bayoen_name-0-0xA000.bin rsrc_raw/decmp/bayoen_name-1-0x2660.bin 16 14 rsrc/orig/grp/bayoen_name_0.png -v 0x0 -o $((0x1c0 * 0)) -p rsrc_raw/pal/bayoen_name.bin
./grpunmap rsrc_raw/decmp/bayoen_name-0-0xA000.bin rsrc_raw/decmp/bayoen_name-1-0x2660.bin 16 14 rsrc/orig/grp/bayoen_name_1.png -v 0x0 -o $((0x1c0 * 1)) -p rsrc_raw/pal/bayoen_name.bin
./grpunmap rsrc_raw/decmp/bayoen_name-0-0xA000.bin rsrc_raw/decmp/bayoen_name-1-0x2660.bin 16 14 rsrc/orig/grp/bayoen_name_2.png -v 0x0 -o $((0x1c0 * 2)) -p rsrc_raw/pal/bayoen_name.bin
./grpunmap rsrc_raw/decmp/bayoen_name-0-0xA000.bin rsrc_raw/decmp/bayoen_name-1-0x2660.bin 16 14 rsrc/orig/grp/bayoen_name_3.png -v 0x0 -o $((0x1c0 * 3)) -p rsrc_raw/pal/bayoen_name.bin
./grpunmap rsrc_raw/decmp/bayoen_name-0-0xA000.bin rsrc_raw/decmp/bayoen_name-1-0x2660.bin 16 14 rsrc/orig/grp/bayoen_name_4.png -v 0x0 -o $((0x1c0 * 4)) -p rsrc_raw/pal/bayoen_name.bin



#./grpunmap rsrc_raw/decmp/cockadoodle-0-0xB000.bin rsrc_raw/decmp/cockadoodle-1-0x2660.bin 16 14 rsrc/orig/grp/cockadoodle_0.png -v 0x100 -o $((0x1c0 * 0)) -p rsrc_raw/pal/cockadoodle.bin
./grpunmap rsrc_raw/decmp/cockadoodle-0-0xB000.bin rsrc_raw/decmp/cockadoodle-1-0x2660.bin 16 14 rsrc/orig/grp/cockadoodle_0.png -v 0x100 -o $((0x1c0 * 0)) -p rsrc_raw/pal/cockadoodle.bin
./grpunmap rsrc_raw/decmp/cockadoodle-0-0xB000.bin rsrc_raw/decmp/cockadoodle-1-0x2660.bin 16 14 rsrc/orig/grp/cockadoodle_1.png -v 0x100 -o $((0x1c0 * 1)) -p rsrc_raw/pal/cockadoodle.bin
./grpunmap rsrc_raw/decmp/cockadoodle-0-0xB000.bin rsrc_raw/decmp/cockadoodle-1-0x2660.bin 16 14 rsrc/orig/grp/cockadoodle_2.png -v 0x100 -o $((0x1c0 * 2)) -p rsrc_raw/pal/cockadoodle.bin
./grpunmap rsrc_raw/decmp/cockadoodle-0-0xB000.bin rsrc_raw/decmp/cockadoodle-1-0x2660.bin 16 14 rsrc/orig/grp/cockadoodle_3.png -v 0x100 -o $((0x1c0 * 3)) -p rsrc_raw/pal/cockadoodle.bin
./grpunmap rsrc_raw/decmp/cockadoodle-0-0xB000.bin rsrc_raw/decmp/cockadoodle-1-0x2660.bin 16 14 rsrc/orig/grp/cockadoodle_4.png -v 0x100 -o $((0x1c0 * 4)) -p rsrc_raw/pal/cockadoodle.bin



./grpdmp_md rsrc_raw/decmp/panotty_main-0-0x9000.bin rsrc_raw/decmp/panotty_main-0-0x9000.png -p rsrc_raw/pal/panotty_line.bin

./grpdmp_md rsrc_raw/decmp/panotty_wah-0-0x9000.bin rsrc_raw/decmp/panotty_wah-0-0x9000.png -p rsrc_raw/pal/panotty_line.bin

./grpdmp_md rsrc_raw/decmp/compile_logo-1-0x2000.bin rsrc_raw/decmp/compile_logo-1-0x2000.png -p rsrc_raw/pal/compile_logo.bin

./grpdmp_md rsrc_raw/decmp/battle_main-2-0x680.bin rsrc_raw/decmp/battle_main-2-0x680.png -p rsrc_raw/pal/battle.bin

./grpdmp_md rsrc_raw/decmp/mrflea-0-0x5600.bin rsrc_raw/decmp/mrflea-0-0x5600.png -p rsrc_raw/pal/mrflea_line.bin

./grpdmp_md rsrc_raw/decmp/karaoke-0-0x0.bin rsrc_raw/decmp/karaoke-0-0x0.png -p rsrc_raw/pal/karaoke_line.bin

./grpdmp_md rsrc_raw/decmp/demon_escape-0-0x5600.bin rsrc_raw/decmp/demon_escape-0-0x5600.png -p rsrc_raw/pal/demon_escape_line.bin

./grpdmp_md rsrc_raw/decmp/escape_doors-0-0x5C80.bin rsrc_raw/decmp/escape_doors-0-0x5C80.png -p rsrc_raw/pal/escape_doors.bin

./grpdmp_md rsrc_raw/decmp/examscore-0-0x2000.bin rsrc_raw/decmp/examscore-0-0x2000.png -p rsrc_raw/pal/examscore_line.bin
./grpdmp_md rsrc_raw/decmp/examscore-1-0x4000.bin rsrc_raw/decmp/examscore-1-0x4000.png -p rsrc_raw/pal/examscore_line.bin

./grpunmap rsrc_raw/decmp/examscore-vram.bin rsrc_raw/decmp/examscore-2-0xE000.bin 64 64 rsrc/orig/grp/examscore_bg.png -p rsrc_raw/pal/examscore.bin

./grpdmp_md rsrc_raw/decmp/badend-1-0x4000.bin rsrc_raw/decmp/badend-1-0x4000.png -p rsrc_raw/pal/badend_line.bin

./grpdmp_md rsrc_raw/decmp/skeletont-0-0x5600.bin rsrc_raw/decmp/skeletont-0-0x5600.png -p rsrc_raw/pal/skeletont_line.bin
./grpdmp_md rsrc_raw/decmp/skeletont-1-0x9000.bin rsrc_raw/decmp/skeletont-1-0x9000.png -p rsrc_raw/pal/skeletont_line.bin

#./grpunmap rsrc_raw/decmp/badend-vram.bin rsrc_raw/decmp/badend-2-0xE000.bin 64 64 rsrc/orig/grp/badend_bg.png -p rsrc_raw/pal/badend.bin

#./grpdmp_md rsrc_raw/decmp/intro_doki-1-0x4000.bin rsrc_raw/decmp/intro_doki-1-0x4000.png -p rsrc_raw/pal/intro_doki.bin

#./grpunmap rsrc_raw/decmp/intro_doki-vram.bin rsrc_raw/decmp/intro_doki-0-0xE000.bin 64 17 rsrc/orig/grp/intro_doki.png

