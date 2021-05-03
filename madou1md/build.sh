
echo "*******************************************************************************"
echo "Setting up environment..."
echo "*******************************************************************************"

set -o errexit

BASE_PWD=$PWD
PATH=".:./asm/bin/:$PATH"
INROM="madou1.md"
OUTROM="madou1_en.md"
WLADX="./wla-dx/binaries/wla-z80"
WLALINK="./wla-dx/binaries/wlalink"

# Location of 68kasm, needed to build VWF hacks
M68KASM="68kasm/68kasm"

cp "$INROM" "$OUTROM"

mkdir -p out

echo "*******************************************************************************"
echo "Building tools..."
echo "*******************************************************************************"

#make blackt
#make libmd
make

if [ ! -f $M68KASM ]; then
  echo "************************************************************************"
  echo "Building 68kasm..."
  echo "************************************************************************"
  
  cd 68kasm
    gcc -std=c99 *.c -o 68kasm
    
#    if [ ! $? -eq 0 ]; then
#      echo "Error compiling 68kasm"
#      exit
#    fi
  cd "$BASE_PWD"
fi

# if [ ! -f $WLADX ]; then
#   
#   echo "********************************************************************************"
#   echo "Building WLA-DX..."
#   echo "********************************************************************************"
#   
#   cd wla-dx
#     cmake -G "Unix Makefiles" .
#     make
#   cd $BASE_PWD
#   
# fi

# ###############################################################################
# # Patch in VWF modifications
# ###############################################################################
# 
# cd 68kasm
# 
#   echo "************************************************************************"
#   echo "Assembling hacks..."
#   echo "************************************************************************"
# 
#   # Assemble code
#   ./68kasm -l bssm_vwf.asm
# 
# cd "$BASE_PWD"
#   
# echo "************************************************************************"
# echo "Patching assembled hacks to ROM..."
# echo "************************************************************************"
# 
# # "Link" output
# ./srecpatch "$OUTROM" "$OUTROM" 0x0 < 68kasm/bssm_vwf.h68

echo "*******************************************************************************"
echo "Building font..."
echo "*******************************************************************************"

mkdir -p out/font
./fontbuild font/ out/font/
./bin2dcb out/font/font.bin > out/asm/font.inc
./bin2dcb out/font/chartable.bin > out/asm/chartable.inc
./bin2dcb out/font/kerning.bin > out/asm/kerning.inc

#convert rsrc/title.png -dither None -remap rsrc/orig/title.png PNG32:rsrc/title.png

echo "*******************************************************************************"
echo "Building tilemaps..."
echo "*******************************************************************************"

mkdir -p out/maps
mkdir -p out/grp

for file in tilemappers/*; do
  echo $file
  ./tilemapper_md "$file"
done

for file in out/maps/bayoen_name_*.bin; do
  ./bin2dcb "$file" > $(dirname $file)/$(basename $file .bin).inc
done

for file in out/maps/cockadoodle_*.bin; do
  ./bin2dcb "$file" > $(dirname $file)/$(basename $file .bin).inc
done

for file in out/maps/karaoke_line*.bin; do
  ./bin2dcb "$file" > $(dirname $file)/$(basename $file .bin).inc
done

echo "*******************************************************************************"
echo "Building sprite text..."
echo "*******************************************************************************"

mkdir -p out/spritetxt

#cp rsrc_raw/decmp/title-2-0x4000.bin
./madou1md_spritetxtbuild script/title.txt rsrc_raw/decmp/title-2-0x4000.bin table/madou1md_en.tbl out/spritetxt/title -o 0x200 -x 120 -y 120 -b 0x200-0x26B -b 0x31C-0x343 -b 0x358-0x36F -b 0x400-0x47F

mkdir -p out/spritetxt_static

./madou1md_staticspritetxtbuild ./ ./

for file in {out/spritetxt/*.bin,out/spritetxt_static/*.bin}; do
#  echo "converting $file"
  ./bin2dcb "$file" > $(dirname $file)/$(basename $file .bin).inc
done;

echo "*******************************************************************************"
echo "Patching graphics..."
echo "*******************************************************************************"

mkdir -p out/grp

./rawgrpconv_md rsrc/grp/intro_doki.png rsrc/grp/intro_doki.txt "rsrc_raw/decmp/intro_doki-1-0x4000.bin" $((0+(0x20*0xe2))) "out/grp/intro_doki-1-0x4000.bin"
./rawgrpconv_md rsrc/grp/intro_bechi.png rsrc/grp/intro_bechi.txt "rsrc_raw/decmp/intro_final-2-0x4000.bin" $((0+(0x20*0x10c))) "out/grp/intro_final-2-0x4000.bin"

cp rsrc_raw/decmp/panotty_wah-0-0x9000.bin out/grp/panotty_wah-0-0x9000.bin
./rawgrpconv_md rsrc/grp/panotty_wah.png rsrc/grp/panotty_wah.txt "out/grp/panotty_wah-0-0x9000.bin" $((0+(0x20*0x38))) "out/grp/panotty_wah-0-0x9000.bin" -p rsrc_raw/pal/panotty_line.bin
./rawgrpconv_md rsrc/grp/panotty_fueen.png rsrc/grp/panotty_fueen.txt "out/grp/panotty_wah-0-0x9000.bin" $((0+(0x20*0x28))) "out/grp/panotty_wah-0-0x9000.bin" -p rsrc_raw/pal/panotty_line.bin

cp rsrc_raw/decmp/panotty_amigo_wah-0-0x3C00.bin out/grp/panotty_amigo_wah-0-0x3C00.bin
./rawgrpconv_md rsrc/grp/panotty_wah.png rsrc/grp/panotty_wah.txt "out/grp/panotty_amigo_wah-0-0x3C00.bin" $((0+(0x20*0x38))) "out/grp/panotty_amigo_wah-0-0x3C00.bin" -p rsrc_raw/pal/panotty_line.bin
./rawgrpconv_md rsrc/grp/panotty_fueen.png rsrc/grp/panotty_fueen.txt "out/grp/panotty_amigo_wah-0-0x3C00.bin" $((0+(0x20*0x28))) "out/grp/panotty_amigo_wah-0-0x3C00.bin" -p rsrc_raw/pal/panotty_line.bin

cp rsrc_raw/decmp/panotty_main-0-0x9000.bin out/grp/panotty_main-0-0x9000.bin
./rawgrpconv_md rsrc/grp/panotty_poka.png rsrc/grp/panotty_poka.txt "out/grp/panotty_main-0-0x9000.bin" $((0+(0x20*0x6b))) "out/grp/panotty_main-0-0x9000.bin" -p rsrc_raw/pal/panotty_line.bin

cp rsrc_raw/decmp/panotty_amigo_main-0-0x3C00.bin out/grp/panotty_amigo_main-0-0x3C00.bin
./rawgrpconv_md rsrc/grp/panotty_poka.png rsrc/grp/panotty_poka.txt "out/grp/panotty_amigo_main-0-0x3C00.bin" $((0+(0x20*0x6b))) "out/grp/panotty_amigo_main-0-0x3C00.bin" -p rsrc_raw/pal/panotty_line.bin

cp rsrc_raw/decmp/compile_logo-1-0x2000.bin out/grp/compile_logo-1-0x2000.bin
./rawgrpconv_md rsrc/grp/compile_logo.png rsrc/grp/compile_logo.txt "out/grp/compile_logo-1-0x2000.bin" $((0+(0x20*0x0))) "out/grp/compile_logo-1-0x2000.bin" -p rsrc_raw/pal/compile_logo.bin

cp rsrc_raw/decmp/battle_main-2-0x680.bin out/grp/battle_main-2-0x680.bin
./rawgrpconv_md rsrc/grp/bayoen_jin.png rsrc/grp/bayoen_jin.txt "out/grp/battle_main-2-0x680.bin" $((0+(0x20*0x21))) "out/grp/battle_main-2-0x680.bin" -p rsrc_raw/pal/battle.bin

cp rsrc_raw/decmp/mrflea-0-0x5600.bin out/grp/mrflea-0-0x5600.bin
./rawgrpconv_md rsrc/grp/mrflea_here.png rsrc/grp/mrflea_here.txt "out/grp/mrflea-0-0x5600.bin" $((0+(0x20*0x4))) "out/grp/mrflea-0-0x5600.bin" -p rsrc_raw/pal/mrflea_line.bin
./rawgrpconv_md rsrc/grp/mrflea_defending.png rsrc/grp/mrflea_defending.txt "out/grp/mrflea-0-0x5600.bin" $((0+(0x20*0x45))) "out/grp/mrflea-0-0x5600.bin" -p rsrc_raw/pal/mrflea_line.bin
./rawgrpconv_md rsrc/grp/mrflea_batankyu.png rsrc/grp/mrflea_batankyu.txt "out/grp/mrflea-0-0x5600.bin" $((0+(0x20*0x24))) "out/grp/mrflea-0-0x5600.bin" -p rsrc_raw/pal/mrflea_line.bin

cp rsrc_raw/decmp/mrflea_amigo-0-0x1C00.bin out/grp/mrflea_amigo-0-0x1C00.bin
./rawgrpconv_md rsrc/grp/mrflea_here.png rsrc/grp/mrflea_here.txt "out/grp/mrflea_amigo-0-0x1C00.bin" $((0+(0x20*0x4))) "out/grp/mrflea_amigo-0-0x1C00.bin" -p rsrc_raw/pal/mrflea_line.bin
./rawgrpconv_md rsrc/grp/mrflea_defending.png rsrc/grp/mrflea_defending.txt "out/grp/mrflea_amigo-0-0x1C00.bin" $((0+(0x20*0x45))) "out/grp/mrflea_amigo-0-0x1C00.bin" -p rsrc_raw/pal/mrflea_line.bin
./rawgrpconv_md rsrc/grp/mrflea_batankyu.png rsrc/grp/mrflea_batankyu.txt "out/grp/mrflea_amigo-0-0x1C00.bin" $((0+(0x20*0x24))) "out/grp/mrflea_amigo-0-0x1C00.bin" -p rsrc_raw/pal/mrflea_line.bin

cp rsrc_raw/decmp/timer-0-0x5600.bin out/grp/timer-0-0x5600.bin
./rawgrpconv_md rsrc/grp/timer_text.png rsrc/grp/timer_text.txt "out/grp/timer-0-0x5600.bin" $((0+(0x20*0x0))) "out/grp/timer-0-0x5600.bin"
./rawgrpconv_md rsrc/grp/timer_digits.png rsrc/grp/timer_digits.txt "out/grp/timer-0-0x5600.bin" $((0+(0x20*0x10))) "out/grp/timer-0-0x5600.bin"

cp rsrc_raw/decmp/karaoke-0-0x0.bin out/grp/karaoke-0-0x0.bin
./datpatch out/grp/karaoke-0-0x0.bin out/grp/karaoke-0-0x0.bin out/grp/karaoke.bin 0x9FE0

cp rsrc_raw/decmp/demon_escape-0-0x5600.bin out/grp/demon_escape-0-0x5600.bin
./rawgrpconv_md rsrc/grp/demon_byun.png rsrc/grp/demon_byun.txt "out/grp/demon_escape-0-0x5600.bin" $((0+(0x20*0x2E))) "out/grp/demon_escape-0-0x5600.bin" -p rsrc_raw/pal/demon_escape_line.bin

cp rsrc_raw/decmp/escape_doors-0-0x5C80.bin out/grp/escape_doors-0-0x5C80.bin
./rawgrpconv_md rsrc/grp/escape_doors.png rsrc/grp/escape_doors.txt "out/grp/escape_doors-0-0x5C80.bin" $((0+(0x20*0x1A))) "out/grp/escape_doors-0-0x5C80.bin" -p rsrc_raw/pal/escape_doors.bin

cp rsrc_raw/decmp/examscore-1-0x4000.bin out/grp/examscore-1-0x4000.bin
./rawgrpconv_md rsrc/grp/examscore_digits.png rsrc/grp/examscore_digits.txt "out/grp/examscore-1-0x4000.bin" $((0+(0x20*0x4A))) "out/grp/examscore-1-0x4000.bin" -p rsrc_raw/pal/examscore_line.bin
./rawgrpconv_md rsrc/grp/exam_pass.png rsrc/grp/exam_pass.txt "out/grp/examscore-1-0x4000.bin" $((0+(0x20*0x0))) "out/grp/examscore-1-0x4000.bin" -p rsrc_raw/pal/examscore_line.bin
./rawgrpconv_md rsrc/grp/exam_fail.png rsrc/grp/exam_fail.txt "out/grp/examscore-1-0x4000.bin" $((0+(0x20*0x76))) "out/grp/examscore-1-0x4000.bin" -p rsrc_raw/pal/examscore_line.bin

cp rsrc_raw/decmp/badend-1-0x4000.bin out/grp/badend-1-0x4000.bin
./rawgrpconv_md rsrc/grp/badend_gan.png rsrc/grp/badend_gan.txt "out/grp/badend-1-0x4000.bin" $((0+(0x20*0x295))) "out/grp/badend-1-0x4000.bin" -p rsrc_raw/pal/badend_line.bin

for file in rsrc_raw/decmp/credits*-0-0x0.bin; do
  cp "$file" "out/grp/"
done

#./rawgrpconv_md rsrc/credits/credits_top_0.png rsrc/grp/credits_top_structure.txt "out/grp/credits0-0-0x0.bin" $((0+(0x20*0x1))) "out/grp/credits0-0-0x0.bin" -p rsrc_raw/pal/credits.bin

for i in `seq 0 9`; do
  ./rawgrpconv_md rsrc/credits/credits_top_${i}.png rsrc/credits/credits_top_structure.txt "out/grp/credits${i}-0-0x0.bin" $((0+(0x20*0x1))) "out/grp/credits${i}-0-0x0.bin" -p rsrc_raw/pal/credits.bin
done

cp rsrc_raw/decmp/skeletont-0-0x5600.bin out/grp/skeletont-0-0x5600.bin
cp rsrc_raw/decmp/skeletont-1-0x9000.bin out/grp/skeletont-1-0x9000.bin
./rawgrpconv_md rsrc/grp/skeletont_cups.png rsrc/grp/skeletont_cups.txt "out/grp/skeletont-0-0x5600.bin" $((0+(0x20*0x0))) "out/grp/skeletont-0-0x5600.bin" -p rsrc_raw/pal/skeletont_line.bin
./rawgrpconv_md rsrc/grp/skeletont_cup_defeated.png rsrc/grp/skeletont_cup_defeated.txt "out/grp/skeletont-1-0x9000.bin" $((0+(0x20*0x0))) "out/grp/skeletont-1-0x9000.bin" -p rsrc_raw/pal/skeletont_line.bin

echo "*******************************************************************************"
echo "Building credits..."
echo "*******************************************************************************"

mkdir -p out/credits
./madou1md_creditsbuild "./" "./"

for file in out/credits/*.bin; do
  ./bin2dcb "$file" > $(dirname $file)/$(basename $file .bin).inc
done;

echo "*******************************************************************************"
echo "Building graphics packs..."
echo "*******************************************************************************"

mkdir -p out/packs
./madou1md_packbuild ./ out/packs/

./datpatch "$OUTROM" "$OUTROM" out/packs/pack240000.bin 0x240000
./datpatch "$OUTROM" "$OUTROM" out/packs/pack250000.bin 0x250000
./datpatch "$OUTROM" "$OUTROM" out/packs/pack260000.bin 0x260000
./datpatch "$OUTROM" "$OUTROM" out/packs/pack270000.bin 0x270000

# mkdir -p out/precmp
# mkdir -p out/grp
# #grpundmp_md rsrc/font.png out/precmp/font.bin 0x90
# #grpundmp_md rsrc/battle_font.png out/grp/battle_font.bin 0x17
# 
# grpundmp_md rsrc/stageinfo.png out/grp/stageinfo.bin 8
# 
# grpundmp_md rsrc/unit_moves_left.png out/grp/unit_moves_left.bin 8
# filepatch "$OUTROM" 0x92CF out/grp/unit_moves_left.bin "$OUTROM"
# 
# grpundmp_md rsrc/resupply_complete.png out/grp/resupply_complete.bin 8
# filepatch "$OUTROM" 0x93CF out/grp/resupply_complete.bin "$OUTROM"
# 
# grpundmp_md rsrc/completed_1.png out/grp/completed_1.bin 12 -r 4
# grpundmp_md rsrc/completed_2.png out/grp/completed_2.bin 12 -r 4
# grpundmp_md rsrc/completed_3.png out/grp/completed_3.bin 12 -r 4
# grpundmp_md rsrc/completed_4.png out/grp/completed_4.bin 12 -r 4
# filepatch "$OUTROM" 0x3161E out/grp/completed_1.bin "$OUTROM"
# filepatch "$OUTROM" 0x3179E out/grp/completed_2.bin "$OUTROM"
# filepatch "$OUTROM" 0x3191E out/grp/completed_3.bin "$OUTROM"
# filepatch "$OUTROM" 0x31A9E out/grp/completed_4.bin "$OUTROM"
# 
# grpundmp_md rsrc/congratulations_continued_1.png out/grp/congratulations_continued_1.bin 6 -r 3
# grpundmp_md rsrc/congratulations_continued_2.png out/grp/congratulations_continued_2.bin 6 -r 3
# filepatch "$OUTROM" 0x69AF3 out/grp/congratulations_continued_1.bin "$OUTROM"
# filepatch "$OUTROM" 0x69BB3 out/grp/congratulations_continued_2.bin "$OUTROM"
# 
# grpundmp_md rsrc/compendium_menulabel.png out/grp/compendium_menulabel.bin 9
# 
# grpundmp_md rsrc/font_credits.png out/grp/font_credits.bin 0x50
 
# echo "*******************************************************************************"
# echo "Building tilemaps..."
# echo "*******************************************************************************"
# 
# mkdir -p out/maps
# mkdir -p out/grp
# 
# for file in tilemappers/*; do
#   tilemapper_md "$file"
# done

# echo "*******************************************************************************"
# echo "Patching graphics..."
# echo "*******************************************************************************"
# 
# cp "rsrc_raw/title_subcomponents.bin" "out/grp/title_subcomponents.bin"

# echo "*******************************************************************************"
# echo "Patching graphics..."
# echo "*******************************************************************************"
# 
# rawgrpconv_md rsrc/button01.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*10))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button02.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*16))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button03.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*22))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button04.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*28))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button05.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*34))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button06.png rsrc/button06.txt $OUTROM $((0x1EA00+(0x20*40))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button07.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*42))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button08.png rsrc/button_savefile.txt $OUTROM $((0x1EA00+(0x20*48))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button09.png rsrc/button_savefile.txt $OUTROM $((0x1EA00+(0x20*50))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button10.png rsrc/button_savefile.txt $OUTROM $((0x1EA00+(0x20*52))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button11.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*54))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button12.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*60))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button13.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*66))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button14.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*72))) $OUTROM -p rsrc_raw/main.pal
# #rawgrpconv_md rsrc/button15.png rsrc/button_structure_generic.txt $OUTROM $((0x1EA00+(0x20*78))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/button15.png rsrc/button_structure_generic.txt out/button_leave_new.bin 0 out/button_leave_new.bin -p rsrc_raw/main.pal
# 
# rawgrpconv_md rsrc/compass_n.png rsrc/compass_structure_generic.txt $OUTROM $((0x22020+(0x20*0))) $OUTROM -p rsrc_raw/main_sprite_distinct.pal
# rawgrpconv_md rsrc/compass_w.png rsrc/compass_structure_generic.txt $OUTROM $((0x22020+(0x20*6))) $OUTROM -p rsrc_raw/main_sprite_distinct.pal
# rawgrpconv_md rsrc/compass_s.png rsrc/compass_structure_generic.txt $OUTROM $((0x22020+(0x20*12))) $OUTROM -p rsrc_raw/main_sprite_distinct.pal
# rawgrpconv_md rsrc/compass_e.png rsrc/compass_structure_generic.txt $OUTROM $((0x22020+(0x20*18))) $OUTROM -p rsrc_raw/main_sprite_distinct.pal
# 
# #rawgrpconv_md rsrc/title_button01.png rsrc/compass_structure_generic.txt $OUTROM $((0x376E0+(0x20*0))) $OUTROM -p rsrc_raw/main.pal
# #rawgrpconv_md rsrc/title_button02.png rsrc/compass_structure_generic.txt $OUTROM $((0x376E0+(0x20*6))) $OUTROM -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/title_button01.png rsrc/compass_structure_generic.txt "out/grp/title_subcomponents.bin" $((0x0+(0x20*0x19))) "out/grp/title_subcomponents.bin" -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/title_button02.png rsrc/compass_structure_generic.txt "out/grp/title_subcomponents.bin" $((0x0+(0x20*0x1F))) "out/grp/title_subcomponents.bin" -p rsrc_raw/main.pal
# rawgrpconv_md rsrc/title_subtitle.png rsrc/title_subtitle.txt "out/grp/title_subcomponents.bin" $((0x0+(0x20*0x25))) "out/grp/title_subcomponents.bin" -p rsrc_raw/title.pal
# 
# cmp1bpp_md rsrc/gold_sign.png out/gold_sign.bin 1
# filepatch $OUTROM $((0x1FAB8+(0xB*8))) "out/gold_sign.bin" $OUTROM

echo "*******************************************************************************"
echo "Building script..."
echo "*******************************************************************************"

#rm -r out/script
mkdir -p out/script
#mkdir -p out/script/strings

# cat together all string files intro one big file for remapping
#cat "script/dialogue.txt" "script/items.txt" "script/menus.txt" "script/spells.txt" > "out/script/dialogue_all.txt"

./madou1md_scriptbuild script/ table/madou1md_en.tbl "$OUTROM" out/script/

# ./bin2dcb out/script/capsule_plural_release_prompt.bin > out/asm/capsule_plural_release_prompt.inc
# ./bin2dcb out/script/capsule_plural_released.bin > out/asm/capsule_plural_released.inc
# ./bin2dcb out/script/monster_encounter_plural.bin > out/asm/monster_encounter_plural.inc
# ./bin2dcb out/script/hungry_elephant_short.bin > out/asm/hungry_elephant_short.inc

for file in out/script/*.bin; do
  ./bin2dcb "$file" > out/asm/$(basename $file .bin).inc
done

# echo "********************************************************************************"
# echo "Applying ASM patches..."
# echo "********************************************************************************"
# 
# mkdir -p "out/asm"
# cp "$OUTROM" "asm/madou1.md"
# 
# cd asm
#   # apply hacks
#   ../$WLADX -I ".." -o "main.o" "main.s"
#   ../$WLALINK -s -v linkfile madou1_patched.md
#   
#   mv -f "madou1_patched.md" "madou1.md"
#   
#   # update region code in header (WLA-DX forces it to 4,
#   # for "export SMS", when the .smstag directive is used
#   # -- we want 7, for "international GG")
#   ../$WLADX -o "main2.o" "main2.s"
#   ../$WLALINK -v linkfile2 madou1_patched.md
# cd "$BASE_PWD"
# 
# mv -f "asm/madou1_patched.md" "$OUTROM"
# mv -f "asm/madou1_patched.sym" "$(basename $OUTROM .md).sym"
# rm "asm/madou1.md"
# rm "asm/main.o"
# rm "asm/main2.o"

echo "********************************************************************************"
echo "Applying ASM patches..."
echo "********************************************************************************"

mkdir -p out/asm
cp asm/madou1md.asm out/asm/madou1md.asm
$M68KASM -l "out/asm/madou1md.asm"
./srecpatch "$OUTROM" "$OUTROM" < out/asm/madou1md.h68

echo "*******************************************************************************"
echo "Finalizing ROM..."
echo "*******************************************************************************"

./romprep "$OUTROM" 0x400000 "$OUTROM"

echo "*******************************************************************************"
echo "Success!"
echo "Output file:" $OUTROM
echo "*******************************************************************************"
