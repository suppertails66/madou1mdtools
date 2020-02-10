#include "md/Madou1MdCmp.h"
#include "util/TBufStream.h"
#include "util/TOpt.h"
#include "util/TStringConversion.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Md;

int charsPerRow = 16;
int charW = 16;
int charH = 16;
int bytesPerChar = charW * charH / 8;

void readFontPattern(TStream& ifs, int offset, TStream& ofs) {
  ifs.seek(offset);
  for (int i = 0; i < 8; i++) {
    ofs.put(ifs.get());
    ifs.get();
  }
}

void fontPatternToGraphic(TStream& ifs, TGraphic& grp, int x, int y) {
  ifs.seek(0);
  for (int j = 0; j < 8; j++) {
    TByte next = ifs.readu8();
    for (int i = 0; i < 8; i++) {
      if ((next & (0x80 >> i)) != 0) {
        grp.setPixel(x + i, y + j,
          TColor(0xFF, 0xFF, 0xFF, TColor::fullAlphaOpacity));
      }
      else {
        grp.setPixel(x + i, y + j,
          TColor(0x00, 0x00, 0x00, TColor::fullAlphaOpacity));
      }
    }
  }
}

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "Madou Monogatari I font extractor" << endl;
    cout << "Usage: "
         << argv[0] << " <infile> <offset> <numchars> <outfile>" << endl;
    
    return 0;
  }
  
  char* infile = argv[1];
  int fontOffset = TStringConversion::stringToInt(string(argv[2]));
  int numChars = TStringConversion::stringToInt(string(argv[3]));
  char* outfile = argv[4];
  
  TBufStream ifs;
  ifs.open(infile);
  
  int outputW = charsPerRow * charW;
  int outputH = numChars / charsPerRow;
  if ((numChars % charsPerRow) != 0) ++outputH;
  outputH *= charH;
  
  TGraphic grp(outputW, outputH);
  grp.clearTransparent();
  
  ifs.seek(fontOffset);
  for (int i = 0; i < numChars; i++) {
    int baseAddr = fontOffset + (i * bytesPerChar);
    
    TBufStream ul;
    TBufStream ur;
    TBufStream ll;
    TBufStream lr;
    
    readFontPattern(ifs, baseAddr +  0, ul);
    readFontPattern(ifs, baseAddr +  1, ur);
    readFontPattern(ifs, baseAddr + 16, ll);
    readFontPattern(ifs, baseAddr + 17, lr);
    
    int x = (i % charsPerRow) * charW;
    int y = (i / charsPerRow) * charH;
    
    fontPatternToGraphic(ul, grp, x + 0, y + 0);
    fontPatternToGraphic(ur, grp, x + 8, y + 0);
    fontPatternToGraphic(ll, grp, x + 0, y + 8);
    fontPatternToGraphic(lr, grp, x + 8, y + 8);
  }
  
  TPngConversion::graphicToRGBAPng(string(outfile), grp);
  
  return 0;
} 
