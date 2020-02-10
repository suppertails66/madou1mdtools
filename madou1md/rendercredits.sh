
tempFontFile=".fontrender_temp"

function render8x16() {
  printf "$2" > $tempFontFile
  ./fontrender "rsrc/karaoke/karaoke_font_8x16.png" "table/madou1md_karaoke_8x16.tbl" 8 16 0xFFFFFFFF 0x00000000 "$tempFontFile" "rsrc/credits/$1.png"
}

function renderCred() {
  printf "$2" > $tempFontFile
  flags="-c"
  if [ "$3" != "" ]; then
    flags=$3
  fi
  
  ./fontrender_vwf "rsrc/karaoke/font_en/font.png" "rsrc/karaoke/font_en/sizetable.txt" "table/madou1md_karaoke_vwf.tbl" 8 8 0xfcd800FF 0x480000FF "$tempFontFile" "rsrc/credits/$1.png" $flags
}

function renderCredHeader() {
  printf "$2" > $tempFontFile
  flags="-c"
  if [ "$3" != "" ]; then
    flags=$3
  fi
  
  ./fontrender_vwf "rsrc/karaoke/font_en/font.png" "rsrc/karaoke/font_en/sizetable.txt" "table/madou1md_karaoke_vwf.tbl" 8 8 0xFFFFFFFF 0x480000FF "$tempFontFile" "rsrc/credits/$1.png" $flags
}

function renderNewCredHeader() {
  printf "$2" > $tempFontFile
  ./fontrender "rsrc/karaoke/karaoke_font_8x16.png" "table/madou1md_karaoke_8x16.tbl" 8 16 0xFFFFFFFF 0x480000FF "$tempFontFile" "rsrc/credits/$1.png"
}

function makeTilemap() {
  jpfile=rsrc/credits/jp_$1.png
  enfile=rsrc/credits/en_$1.png
  outfile=rsrc/credits/tilemap_$1.png
  
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

function fix9b {
  convert "rsrc/credits/$1.png" -background \#480000 -extent 100%x200%+0-4 "PNG32:rsrc/credits/$1.png"
}

make blackt && make fontrender
make blackt && make fontrender_vwf
#mkdir -p out/credits

>$tempFontFile

#renderJp jp_line0 " Madou Monogatari wa tottemo tanoshii "

renderCred credits_0-0 "Producer"
renderCred credits_0-1 "MOO Niitani"

renderCred credits_1-0 "Director"
renderCred credits_1-1 "Katsuji Suenaga"

renderCred credits_2-0 "Planners"
renderCred credits_2-1 "Kasumi Hakuryuho"
renderCred credits_2-2 "Doctor K-Mi"

renderCred credits_3-0 "Programmers"
renderCred credits_3-1 "Yasutoshi Akiyama"
renderCred credits_3-2 "Shinichi Nogami"
#renderCred credits_3-3 "TAKIN"

renderCred credits_4-0 "Graphic Designers"
renderCred credits_4-1 "Kemi"

renderCred credits_5-0 "Sound & Sampling"
renderCred credits_5-1 "T.Matsushima"
renderCred credits_5-2 "Polygon Junkie"

renderCred credits_6-0 "Sound Driver"

renderCred credits_7-0 "Package & Manual"
renderCred credits_7-1 "Amon"
renderCred credits_7-2 "Kazuto Hisoku"
#renderCred credits_7-3 "(meat girl)" "-p"
renderCred credits_7-3 "Kazuto Hisoku (meat girl)[space8px][space4px]"
renderCred credits_7-4 "[space8px][space8px][space8px][space8px][space8px][space8px][space8px][space4px] (meat girl)[space8px][space4px]"
renderCred credits_7-5 "Ichi"
renderCred credits_7-6 "{I want you. All of you!}"

renderCred credits_8-0 "Sampling Voice"
renderCred credits_8-1 "Mami Inoue"

renderCred credits_9-0 "Cooperation"
renderCred credits_9-1 "Gennosuke Yumi"
renderCred credits_9-2 "Rie Otsuka"
renderCred credits_9-3 "Megumi Sano"
renderCred credits_9-4 "Naoki Fujii"
renderCred credits_9-5 "Koki Ishima"
renderCred credits_9-6 "Kenshiro Kuromasa"
renderCred credits_9-7 "Everyone at Compile"

renderNewCredHeader credits_10-0 "English Conversion"
renderNewCredHeader credits_10-1 "Translation"
renderCred       credits_10-2 "TheMajinZenki"
renderNewCredHeader credits_10-3 "Hacking"
renderCred       credits_10-4 "Supper"
renderNewCredHeader credits_10-5 "Editing & Testing"
renderCred       credits_10-6 "cccmar"
renderNewCredHeader credits_10-7 "Original Script Dump"
renderCred       credits_10-8 "Filler"
renderNewCredHeader credits_10-9 "Testing"
renderCred       credits_10-10 "Xanathis"
renderNewCredHeader credits_10-11 "Testing"
renderCred       credits_10-12 "Oddoai-sama"

fix9b credits_9-2
fix9b credits_9-3
fix9b credits_9-4
fix9b credits_9-5
fix9b credits_9-6

render8x16 credits_top_0 "                      "
render8x16 credits_top_0 "       Producer       "
render8x16 credits_top_1 "       Director       "
render8x16 credits_top_2 "       Planners       "
render8x16 credits_top_3 "     Programmers      "
render8x16 credits_top_4 "  Graphic Designers   "
render8x16 credits_top_5 "   Sound & Sampling   "
render8x16 credits_top_6 "     Sound Driver     "
render8x16 credits_top_7 "   Package & Manual   "
render8x16 credits_top_8 "    Sampling Voice    "
render8x16 credits_top_9 "     Cooperation      "

#makeTilemap line0

rm $tempFontFile
 
