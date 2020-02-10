#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TColor.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "util/TPngConversion.h"
#include <vector>
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
  if (argc < 9) {
    cout << "Monospace font renderer" << endl;
    cout << "Usage: " << argv[0]
      << " <font> <table> <w> <h> <fgcolor> <bgcolor> <textfile> <outfile>"
      << endl;
    cout << "Foreground/background colors are in the format 0xRRGGBBAA"
      << endl
      << "(alpha of 0xFF = fully opaque, 0x00 = fully transparent)" << endl;
    
    return 0;
  }
  
  string fontName = string(argv[1]);
  string tableName = string(argv[2]);
  charW = TStringConversion::stringToInt(string(argv[3]));
  charH = TStringConversion::stringToInt(string(argv[4]));
  fgColor = intToColor(TStringConversion::stringToUint(string(argv[5])));
  bgColor = intToColor(TStringConversion::stringToUint(string(argv[6])));
  std::string textFileName = argv[7];
  std::string outFileName = argv[8];
  
//  TThingyTable table;
  table.readSjis(tableName.c_str());
  
  TPngConversion::RGBAPngToGraphic(fontName, fontSheet);
  
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
  }
  
  int width = fontIndices.size() * charW;
  int height = charH;
  
  TGraphic grp(width, height);
  for (unsigned int i = 0; i < fontIndices.size(); i++) {
    int index = fontIndices[i];
    renderChar(index, grp, i * charW, 0);
  }
  
  TPngConversion::graphicToRGBAPng(outFileName, grp);
  
  return 0;
}
