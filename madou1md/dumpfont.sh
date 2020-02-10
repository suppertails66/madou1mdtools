
make libmd && make madou1md_fontdmp

mkdir -p rsrc/orig/font
./madou1md_fontdmp madou1.md 0xBF000 0x80 rsrc/orig/font/kana.png
./madou1md_fontdmp madou1.md 0xB4FC0 0x182 rsrc/orig/font/kanji.png
