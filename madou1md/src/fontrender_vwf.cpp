#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TColor.h"
#include "util/TStringConversion.h"
#include "util/TIniFile.h"
#include "util/TThingyTable.h"
#include "util/TPngConversion.h"
#include "util/TOpt.h"
#include <vector>
#include <map>
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Sms;

TThingyTable table;
int charW;
int charH;
TColor fgColor;
TColor bgColor;
TBufStream ifs;
TGraphic fontSheet;
std::map<int, int> sizeTable;
bool centerOnPattern = false;
bool roundToPatternBoundary = false;

const int charsPerRow = 16;

string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHexPrefix(int num) {
  return "$" + as2bHex(num) + "";
}

TColor intToColor(unsigned int value) {
  TColor result;
  result.setR((value & 0xFF000000) >> 24);
  result.setG((value & 0x00FF0000) >> 16);
  result.setB((value & 0x0000FF00) >> 8);
  result.setA((value & 0x000000FF));
  return result;
}

void renderChar(int charIndex,
                TGraphic& dst,
                int dstX, int dstY) {
  int charX = charIndex % charsPerRow;
  int charY = charIndex / charsPerRow;
  int srcX = charX * charW;
  int srcY = charY * charH;
  
  for (int j = 0; j < charH; j++) {
    for (int i = 0; i < charW; i++) {
      TColor color = fontSheet.getPixel(srcX + i, srcY + j);
      
      if ((color.a() == TColor::fullAlphaTransparency)
          || (color.r() != 0xFF)) {
        // background
        dst.setPixel(dstX + i, dstY + j, bgColor);
      }
      else {
        // foreground
        dst.setPixel(dstX + i, dstY + j, fgColor);
      }
      
    }
  }
}

int main(int argc, char* argv[]) {
  if (argc < 10) {
    cout << "Variable-width font renderer" << endl;
    cout << "Usage: " << argv[0]
      << " <font> <sizetable> <table> <w> <h> <fgcolor> <bgcolor> <textfile>"
      << " <outfile> [options]"
      << endl;
    cout << "Foreground/background colors are in the format 0xRRGGBBAA"
      << endl
      << "(alpha of 0xFF = fully opaque, 0x00 = fully transparent)" << endl;
    cout << "Options:" << endl;
    cout << "  -c     Center output on pattern (8-pixel) boundaries" << endl;
    cout << "  -p     Round width up to pattern (8-pixel) boundary" << endl;
    
    return 0;
  }
  
  string fontName = string(argv[1]);
  string sizeTableName = string(argv[2]);
  string tableName = string(argv[3]);
  charW = TStringConversion::stringToInt(string(argv[4]));
  charH = TStringConversion::stringToInt(string(argv[5]));
  fgColor = intToColor(TStringConversion::stringToUint(string(argv[6])));
  bgColor = intToColor(TStringConversion::stringToUint(string(argv[7])));
  std::string textFileName = argv[8];
  std::string outFileName = argv[9];
  
  if (TOpt::hasFlag(argc, argv, "-c")) {
    centerOnPattern = true;
  }
  
  if (TOpt::hasFlag(argc, argv, "-p")) {
    roundToPatternBoundary = true;
  }
  
  {
    TIniFile sizeTableRaw;
    sizeTableRaw.readFile(sizeTableName);
    for (int i = 0; i < 0x100; i++) {
      string key = as2bHex(i);
      if (sizeTableRaw.hasKey("", key)) {
        sizeTable[i] = TStringConversion::stringToInt(
          sizeTableRaw.valueOfKey("", key));
      }
      else {
        sizeTable[i] = 0;
      }
    }
  }
  
//  TThingyTable table;
  table.readSjis(tableName.c_str());
  
  TPngConversion::RGBAPngToGraphic(fontName, fontSheet);
  
  int width = 0;
  int height = charH;
  
//  TBufStream ifs;
  ifs.open(textFileName.c_str());
  std::vector<int> fontIndices;
  while (!ifs.eof()) {
    while (!ifs.eof()
          && ((ifs.peek() == '\n') || (ifs.peek() == '\r'))) ifs.get();
    if (ifs.eof()) break;
    
    TThingyTable::MatchResult result = table.matchTableEntry(ifs);
    if (result.id == -1) {
      cerr << "Error: could not match character at "
        << ifs.data().data() + ifs.tell()
        << endl;
      return 1;
    }
    
    fontIndices.push_back(result.id);
    width += sizeTable[result.id];
  }
  
  int xpos = 0;
  
  if (centerOnPattern) {
/*    int centerOffset = ((8 - (width % 8)) / 2) % 4;
    width += centerOffset;
    // round width up to nearest pattern boundary
//    if ((width % 8) != 0) width += (8 - (width % 8));
    roundToPatternBoundary = true;
    xpos = centerOffset; */
    
    // FIXME: HACK HACK HACK
    int centerOffset = ((320 - width) / 2) % 8;
    width += centerOffset;
    roundToPatternBoundary = true;
    xpos = centerOffset;
  }
  
  if (roundToPatternBoundary) {
    // round width up to nearest pattern boundary
    if ((width % 8) != 0) width += (8 - (width % 8));
  }
  
  TGraphic grp(width, height);
  grp.fillRect(0, 0, width, height, bgColor);
  
  for (unsigned int i = 0; i < fontIndices.size(); i++) {
    int index = fontIndices[i];
    renderChar(index, grp, xpos, 0);
    xpos += sizeTable[index];
  }
  
  TPngConversion::graphicToRGBAPng(outFileName, grp);
  
  return 0;
}
