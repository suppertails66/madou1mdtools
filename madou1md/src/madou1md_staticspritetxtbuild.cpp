#include "util/TStringConversion.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TThingyTable.h"
#include "util/TOpt.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "md/MdPattern.h"
#include "madou1md/Madou1MdScriptReader.h"
#include "madou1md/Madou1MdLineWrapper.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include <string>
#include <map>
#include <fstream>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Md;

  
//string inScript;
//string inGrp;
string inPrefix;
//string tableName;
string outPrefix;

TBufStream grpOfs;
std::map<int, bool> blacklist;
int tileOrigin = 0;
int baseXOffset = 0;
int baseYOffset = 0;
int textNum = 0;
int tileNum = 0;

const int spaceIndex = 0x004A;

bool isBlacklisted(int num) {
  return (blacklist.find(num) != blacklist.end());
}

int getNextAvailableTile(int num) {
  while (isBlacklisted(num)) ++num;
  return num;
}

int getNextAvailableTileBlock(int num, int numTiles) {
  while (true) {
    bool done = true;
    for (int i = 0; i < numTiles; i++) {
      if (isBlacklisted(num + i)) {
        done = false;
        break;
      }
    }
    
    if (done) return num;
    ++num;
  }
}

void blacklistRange(int start, int end) {
  for (int i = start; i <= end; i++) blacklist[i] = true;
}

void grpToDat(TGraphic& grp, TStream& dst,
              int xOffset, int yOffset) {
  for (int j = 0; j < 8; j++) {
    for (int i = 0; i < 4; i++) {
      int x = xOffset + (i * 2);
      int y = yOffset + j;
      
      TByte result = 0;
      
      TColor color = grp.getPixel(x + 0, y);
      if (color.a() != TColor::fullAlphaTransparency) {
        result |= 0xF0;
      }
      
      color = grp.getPixel(x + 1, y);
      if (color.a() != TColor::fullAlphaTransparency) {
        result |= 0x0F;
      }
      
      dst.put(result);
    }
  }
}

void charToGrpDat(TGraphic& grp, TStream& dst,
                  int xOffset, int yOffset) {
  grpToDat(grp, dst, xOffset + 0, yOffset + 0);
  grpToDat(grp, dst, xOffset + 0, yOffset + 8);
  grpToDat(grp, dst, xOffset + 8, yOffset + 0);
  grpToDat(grp, dst, xOffset + 8, yOffset + 8);
}

void doNextSpriteText(std::string inGrpName,
                      std::string outStructName,
                      bool fixedLength = false) {
  TGraphic grp;
  TPngConversion::RGBAPngToGraphic(inGrpName, grp);
  
  TBufStream ofs;
  
  // output number of entries
  int charW = grp.w() / 16;
  if (fixedLength) ofs.writeu16be(charW);
  
  int xOffset = 0;
  for (int i = 0; i < charW; i++) {
    tileNum = getNextAvailableTileBlock(tileNum, 4);
    int grpIndexNum = tileNum;
    
    grpOfs.seek((grpIndexNum - tileOrigin) * 0x20);
    charToGrpDat(grp, grpOfs, (i * 16), 0);
    
    // write sprite entry
    
    // number of subsprites
    if (!fixedLength) ofs.writeu16be(0x0001);
    
    // vertical position
    ofs.writeu16be(baseYOffset);
    
    // size + dummy link data
    int sizeH = 1;
    int sizeW = 1;
    int sizeOutput = 0;
    sizeOutput |= (sizeW << 10);
    sizeOutput |= (sizeH << 8);
    ofs.writeu16be(sizeOutput);
    
    // identifier (priority, palette, and flip are all assumed zero)
    ofs.writeu16be(grpIndexNum);
    
    // xpos
//    ofs.writeu16be((i * 16) + baseXOffset);
    ofs.writeu16be(baseXOffset + xOffset);
    
    tileNum += 4;
    if (fixedLength) xOffset += 16;
  }
  
  ofs.save(outStructName.c_str());
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Madou Monogatari I (Mega Drive) static sprite text builder"
      << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [outprefix]"
      << endl;
//    cout << "Options:" << endl;
//    cout << "  -o     Set origin tile num for graphics (default: 0)" << endl;
//    cout << "  -x     Set base x-position (default: 0)" << endl;
//    cout << "  -y     Set base y-position (default: 0)" << endl;
//    cout << "  -b     Add blacklisted tiles" << endl;
    
    return 0;
  }
  
  inPrefix = string(argv[1]);
  outPrefix = string(argv[2]);
  
//  TOpt::readNumericOpt(argc, argv, "-o", &tileOrigin);
//  tileNum = tileOrigin;
  
//  TOpt::readNumericOpt(argc, argv, "-x", &baseXOffset);
//  TOpt::readNumericOpt(argc, argv, "-y", &baseYOffset);
  
  // title
  {
    // set up
    grpOfs.open((inPrefix + "out/spritetxt/title-tiles.bin").c_str());
    blacklist.clear();
    blacklistRange(0x200, 0x26B);
    blacklistRange(0x31C, 0x343);
    blacklistRange(0x358, 0x36F);
    blacklistRange(0x400, 0x47F);
    baseXOffset = 120;
    baseYOffset = 120;
    tileOrigin = 0x200;
    tileNum = 0x344;
    textNum = 0;
    
    doNextSpriteText(
      "rsrc/grp/newgame.png", "out/spritetxt_static/newgame.bin");
    doNextSpriteText(
      "rsrc/grp/continue.png", "out/spritetxt_static/continue.bin");
    doNextSpriteText(
      "rsrc/grp/present.png", "out/spritetxt_static/present.bin");
    doNextSpriteText(
      "rsrc/grp/journal1.png", "out/spritetxt_static/journal1.bin");
    doNextSpriteText(
      "rsrc/grp/journal2.png", "out/spritetxt_static/journal2.bin");
    doNextSpriteText(
      "rsrc/grp/sorcerysong.png", "out/spritetxt_static/sorcerysong.bin");
    doNextSpriteText(
      "rsrc/grp/samples.png", "out/spritetxt_static/samples.bin",
      true);
    doNextSpriteText(
      "rsrc/grp/soundtest.png", "out/spritetxt_static/soundtest.bin",
      true);
    
    grpOfs.save((outPrefix + "out/spritetxt/title-tiles.bin").c_str());
  }
  
  return 0;
}

