
tempFontFile=".fontrender_temp"

function renderJp() {
#  ./fontrender "rsrc/karaoke/karaoke_font_8x16.png" "table/madou1md_karaoke_8x16.tbl" 8 16 0x00000000 0x111111FF "$1" "$2"
#  ./fontrender "rsrc/karaoke/karaoke_font_8x16.png" "table/madou1md_karaoke_8x16.tbl" 8 16 0x00000000 0x111111FF "rsrc/karaoke/jp_$1.txt" "rsrc/karaoke/jp_$1.png"
  printf "$2" > $tempFontFile
  ./fontrender "rsrc/karaoke/karaoke_font_8x16.png" "table/madou1md_karaoke_8x16.tbl" 8 16 0x00000000 0x000000FF "$tempFontFile" "rsrc/karaoke/$1.png"
}

function renderEn() {
  printf "$2" > $tempFontFile
#  ./fontrender "rsrc/karaoke/karaoke_font_8x8.png" "table/madou1md_karaoke_8x8.tbl" 8 8 0xFFFFFFFF 0x000000FF "$tempFontFile" "rsrc/karaoke/$1.png"
  ./fontrender_vwf "rsrc/karaoke/font_en/font.png" "rsrc/karaoke/font_en/sizetable.txt" "table/madou1md_karaoke_vwf.tbl" 8 8 0xfcb400FF 0x000000FF "$tempFontFile" "rsrc/karaoke/$1.png"
}

function makeTilemap() {
  jpfile=rsrc/karaoke/jp_$1.png
  enfile=rsrc/karaoke/en_$1.png
  outfile=rsrc/karaoke/tilemap_$1.png
  
#  if [ ! -f $outfile ]; then
#  fi
#  convert -size 304x24 xc: -alpha transparent "$outfile"
  
#  composite -geometry +0+0 "$jpfile" "$outfile" "$outfile"
#  composite -geometry +0+16 "$enfile" "$outfile" "$outfile"
  
  convert -size 304x24 xc:#000000 -alpha set \
    "$jpfile" -geometry +0+0 -compose Copy -composite \
    "$enfile" -gravity South -compose Copy -composite \
    "PNG32:$outfile"
}

make blackt && make fontrender
make blackt && make fontrender_vwf
#mkdir -p out/karaoke

>$tempFontFile

# renderJp jp_line0 "-Madou Monogatari wa tottemo tanoshii-"
# renderJp jp_line1 "----Minna de perapera shaberimasu-----"
# renderJp jp_line2 "----Odori tsukarete hetoheto nanda----"
# renderJp jp_line3 "-----Bakabakashii kedo mata odoru-----"
# renderJp jp_line4 "------Dance Dance de higakurete-------"
# renderJp jp_line5 "-----Mambo Mambo de hi ga noboru------"
# renderJp jp_line6 "--Rakkyou tabetara genki ni naru yo---"
# renderJp jp_line7 "-Tottemo genki puppakapuu no puu puu--"
# renderJp jp_line8 "-Madou ondo de puppakapuu no puu puu--"
# renderJp jp_line9 " "
# renderJp jp_line10 " "

renderJp jp_line0 " Madou Monogatari wa tottemo tanoshii "
renderJp jp_line1 "    Minna de perapera shaberimasu     "
renderJp jp_line2 "    Odori tsukarete hetoheto nanda    "
renderJp jp_line3 "     Bakabakashii kedo mata odoru     "
renderJp jp_line4 "      Dance Dance de higakurete       "
renderJp jp_line5 "     Mambo Mambo de hi ga noboru      "
renderJp jp_line6 "  Rakkyou tabetara genki ni naru yo   "
renderJp jp_line7 " Tottemo genki puppakapuu no puu puu  "
renderJp jp_line8 " Madou ondo de puppakapuu no puu puu  "
renderJp jp_line9 " "
renderJp jp_line10 " "

# renderEn en_line0 "Sorcery Saga is such a funny game"
# renderEn en_line1 "Every character has a voice clip"
# renderEn en_line2 "Dancing so much is completely exhausting"
# renderEn en_line3 "It's kinda silly, but I'll dance some more"
# renderEn en_line4 "Dance, Dance, until it gets dark"
# renderEn en_line5 "Mambo, Mambo, until the sun rises"
# renderEn en_line6 "Eat some Veggies and you're going to feel good"
# renderEn en_line7 "Super duper great, puppakapuu no puu puu"
# renderEn en_line8 "It's the Sorcery Dance, puppakapuu no puu puu"

# renderEn en_line0 "Sorcery Saga is such a funny game"
# renderEn en_line1 "Every character has a voice clip"
# renderEn en_line2 "Dancing so much is completely exhausting"
# renderEn en_line3 "It's kinda silly, but I'll dance some more"
# renderEn en_line4 "Dance, Dance, until it gets dark"
# renderEn en_line5 "Mambo,[space2px]Mambo, until the sun rises"
# renderEn en_line6 "Eat some Veggies and you're going to feel good"
# renderEn en_line7 "[space1px]Super duper great, puppakapuu no puu puu"
# renderEn en_line8 "It's the Sorcery Dance, puppakapuu no puu puu[space1px]"

renderEn en_line0 "Sorcery Saga is such a funny game"
renderEn en_line1 "Every character has a voice clip"
renderEn en_line2 "Dancing so much is completely exhausting"
renderEn en_line3 "It's kinda silly, but I'll dance some more"
renderEn en_line4 "Dance, Dance, until it gets dark"
renderEn en_line5 "Mambo, Mambo, until the sun rises"
renderEn en_line6 "Eat some Veggies and you're going to feel good"
renderEn en_line7 "Super duper great, happy go lucky go go"
renderEn en_line8 "It's the Sorcery Dance, happy go lucky go go"
renderEn en_line9 " "
renderEn en_line10 " "

#makeTilemap "rsrc/karaoke/jp_line0.png" "rsrc/karaoke/en_line0.png"  "rsrc/karaoke/tilemap_line0.png"
makeTilemap line0
makeTilemap line1
makeTilemap line2
makeTilemap line3
makeTilemap line4
makeTilemap line5
makeTilemap line6
makeTilemap line7
makeTilemap line8
makeTilemap line9
makeTilemap line10

rm $tempFontFile
 
