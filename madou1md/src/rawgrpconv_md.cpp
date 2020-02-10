#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TThingyTable.h"
#include "util/TParse.h"
#include "util/TOpt.h"
#include "util/TFileManip.h"
#include "md/MdPattern.h"
#include "md/MdPaletteLine.h"
#include "exception/TGenericException.h"
#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Md;

TBufStream patchifs(1);
TGraphic grp;
TBufStream ofs(1);

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "Mega Drive raw graphic patcher" << endl;
    cout << "Usage: " << argv[0]
      << " <ingraphic> <structfile> <srcfile> <srcoffset> <outfile>" << endl;
    cout << "Options:" << endl;
    cout << "  p    Specify palette file" << endl;
    
    return 0;
  }

  TPngConversion::RGBAPngToGraphic(string(argv[1]), grp);
  patchifs.open(argv[2]);
  
  string infile = string(argv[3]);
  if (TFileManip::fileExists(infile))
    ofs.open(infile.c_str());
  else
    // create new file
    ofs = TBufStream(0x10000);
  
  int srcoffset = TStringConversion::stringToInt(string(argv[4]));
  
  MdPaletteLine* palptr = NULL;
  char* palettename = TOpt::getOpt(argc, argv, "-p");
  MdPaletteLine pal;
  bool colorsUsed[16];
  bool colorsAvailable[16];
  if (palettename != NULL) {
//    TIfstream palifs(argv[4], ios_base::binary);
    TBufStream palifs;
    palifs.open(palettename);
    pal = MdPaletteLine((TByte*)palifs.data().data());
    palptr = &pal;
    for (int i = 0; i < 16; i++) {
      colorsUsed[i] = true;
      colorsAvailable[i] = true;
    }
  }
  
  int w = (grp.w() / MdPattern::w);
  int h = (grp.h() / MdPattern::h);
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      int patternNum = TParse::matchInt(patchifs);
      if (patternNum == -1) continue;
      
      int x = (i * MdPattern::w);
      int y = (j * MdPattern::h);
      
      MdPattern pattern;
//      pattern.fromGrayscaleGraphic(grp, x, y);
    
      if (palptr != NULL) {
//        pattern.approximateGraphic(grp, *palptr, colorsUsed, colorsAvailable,
//                                   x, y, false, true, true);
        int result = pattern.fromColorGraphic(grp, pal, x, y);
        if (result != 0) {
          cerr << "Error: Graphic uses colors not in palette" << endl;
          return 1;
        }
      }
      else {
        pattern.fromGrayscaleGraphic(grp, x, y);
      }
      
      ofs.seek(srcoffset + (patternNum * MdPattern::uncompressedSize));
      pattern.write(ofs);
    }
  }
  
  ofs.save(argv[5]);
  
  return 0;
}
