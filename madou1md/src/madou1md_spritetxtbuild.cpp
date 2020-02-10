#include "util/TStringConversion.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TThingyTable.h"
#include "util/TOpt.h"
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

  
string inScript;
string inGrp;
string tableName;
string outPrefix;

TBufStream grpOfs;
TThingyTable table;
TBufStream font;
Madou1MdLineWrapper::CharSizeTable sizeTable;
Madou1MdLineWrapper::KerningMatrix kerningMatrix;
std::map<int, bool> blacklist;
std::map<int, int> indexTileMap;
int tileOrigin = 0;
int baseXOffset = 0;
int baseYOffset = 0;
int textNum = 0;
int tileNum = 0;

const int bytesPerInputFontChar = 0x400;
const int bytesPerLocalFontChar = 0x80;

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

void doNextSpriteText(TStream& scriptifs) {
  Madou1MdScriptReader::ResultCollection results;
  Madou1MdScriptReader(scriptifs, results, table)();
  
  if (results.size() <= 0) return;
  
  Madou1MdScriptReader::ResultString& result = results[0];
  TBufStream ifs;
  ifs.write(result.str.c_str(), result.str.size());
  ifs.seek(0);
  
  TBufStream ofs;
  // dummy entry for number of output characters
  ofs.writeu16be(0);
  
  int xOffset = 0;
  int numOutputSprites = 0;
  while (!ifs.eof()) {
    // get index number of next character
    int nextIndex = ifs.readu16be();
    
    // spaces do not need to be rendered
    if (nextIndex == spaceIndex) {
      xOffset += sizeTable[nextIndex].advanceWidth;
      continue;
    }
    
    int charW = sizeTable[nextIndex].glyphWidth;
    int advanceW = sizeTable[nextIndex].advanceWidth;
    font.seek(nextIndex * bytesPerLocalFontChar);
//    tileNum = getNextAvailableTile(tileNum);

    // write graphics data (if character not already used)
    
    int grpIndexNum;
    map<int, int>::iterator usedIt = indexTileMap.find(nextIndex);
    if (usedIt != indexTileMap.end()) {
      grpIndexNum = usedIt->second;
    }
    else {
      if (charW > 8) {
        // double width
        tileNum = getNextAvailableTileBlock(tileNum, 4);
        grpOfs.seek((tileNum - tileOrigin) * 0x20);
        grpOfs.writeFrom(font, 0x80);
        indexTileMap[nextIndex] = tileNum;
        grpIndexNum = tileNum;
        tileNum += 4;
      }
      else {
        // single width
        tileNum = getNextAvailableTileBlock(tileNum, 2);
        grpOfs.seek((tileNum - tileOrigin) * 0x20);
        grpOfs.writeFrom(font, 0x40);
        indexTileMap[nextIndex] = tileNum;
        grpIndexNum = tileNum;
        tileNum += 2;
      }
    }
    
    // write sprite entry
    
    // number of subsprites
    ofs.writeu16be(0x0001);
    
    // vertical position
    ofs.writeu16be(baseYOffset);
    
    // size + dummy link data
    int sizeH = 1;
    int sizeW = (charW > 8) ? 1 : 0;
    int sizeOutput = 0;
    sizeOutput |= (sizeW << 10);
    sizeOutput |= (sizeH << 8);
    ofs.writeu16be(sizeOutput);
    
    // identifier (priority, palette, and flip are all assumed zero)
    ofs.writeu16be(grpIndexNum);
    
    // xpos
    ofs.writeu16be(xOffset + baseXOffset);
    
    xOffset += advanceW;
    ++numOutputSprites;
  }
  
  // fill in number of output sprites
  ofs.seek(0);
  ofs.writeu16be(numOutputSprites);
  
  std::string outName = outPrefix
    + "-"
    + TStringConversion::intToString(textNum)
    + ".bin";
  ofs.save(outName.c_str());
  
  ++textNum;
}

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "Madou Monogatari I (Mega Drive) sprite text builder" << endl;
    cout << "Usage: " << argv[0] << " [inscript] [ingrp] [thingy] [outprefix]"
      << endl;
    cout << "Options:" << endl;
    cout << "  -o     Set origin tile num for graphics (default: 0)" << endl;
    cout << "  -x     Set base x-position (default: 0)" << endl;
    cout << "  -y     Set base y-position (default: 0)" << endl;
    cout << "  -b     Add blacklisted tiles" << endl;
    
    return 0;
  }
  
  inScript = string(argv[1]);
  inGrp = string(argv[2]);
  tableName = string(argv[3]);
//  string romName = string(argv[3]);
  outPrefix = string(argv[4]);
  
  TOpt::readNumericOpt(argc, argv, "-o", &tileOrigin);
  tileNum = tileOrigin;
  
  TOpt::readNumericOpt(argc, argv, "-x", &baseXOffset);
  TOpt::readNumericOpt(argc, argv, "-y", &baseYOffset);
  
  grpOfs.open(inGrp.c_str());
  
  // generate blacklist
  for (int i = 1; i < argc - 1; i++) {
    if (strcmp(argv[i], "-b") != 0) continue;
    
    TBufStream input;
    input.writeCstr(argv[i + 1]);
    input.seek(0);
    while (!input.eof()) {
      string first;
      while (!input.eof() && (input.peek() != '-')) {
        first += input.get();
      }
      
      string second;
      bool hasSecond = false;
      if (!input.eof()) hasSecond = true;
      input.get();
      while (!input.eof()) {
        second += input.get();
      }
      
      int firstNum = TStringConversion::stringToInt(first);
      int secondNum = firstNum;
      if (hasSecond) secondNum = TStringConversion::stringToInt(second);
      
      for (int i = firstNum; i <= secondNum; i++) {
        blacklist[i] = true;
      }
    }
  }
  
  table.readSjis(tableName);
  
//  TBufStream rom;
//  rom.open(romName.c_str());

  int numChars = 0;
  
  // read size table
  {
    TBufStream ifs;
    ifs.open("out/font/chartable.bin");
    
    int pos = 0;
    while (!ifs.eof()) {
      Madou1MdLineWrapper::SizeTableEntry entry;
      entry.glyphWidth = ifs.readu8();
      entry.advanceWidth = ifs.readu8();
      sizeTable[pos++] = entry;
    }
    
    numChars = pos;
  }
  
  // read kerning matrix
//    Madou1MdLineWrapper::KerningMatrix kerningMatrix(numChars, numChars);
  kerningMatrix.resize(numChars, numChars);
  {
    TBufStream ifs;
    ifs.open("out/font/kerning.bin");
    
    for (int j = 0; j < numChars; j++) {
      for (int i = 0; i < numChars; i++) {
        kerningMatrix.data(i, j) = ifs.reads8();
      }
    }
  }
  
  // read font
  {
    TBufStream ifs;
    ifs.open("out/font/font.bin");
    
    for (int i = 0; i < numChars; i++) {
      int charBase = (i * bytesPerInputFontChar);
    
      // ul
      ifs.seek(charBase + 0x0);
      for (int j = 0; j < 8; j++) {
        font.writeFrom(ifs, 4);
        ifs.seekoff(12);
      }
      
      // ll
      ifs.seek(charBase + 0x80);
      for (int j = 0; j < 8; j++) {
        font.writeFrom(ifs, 4);
        ifs.seekoff(12);
      }
      
      // ur
      ifs.seek(charBase + 0x0);
      for (int j = 0; j < 8; j++) {
        ifs.seekoff(4);
        font.writeFrom(ifs, 4);
        ifs.seekoff(8);
      }
      
      // lr
      ifs.seek(charBase + 0x80);
      for (int j = 0; j < 8; j++) {
        ifs.seekoff(4);
        font.writeFrom(ifs, 4);
        ifs.seekoff(8);
      }
    }
  }
  
  {
    TBufStream ifs;
//      ifs.open((inPrefix + "title.txt").c_str());
    ifs.open(inScript.c_str());
    
    while (!ifs.eof()) {
      doNextSpriteText(ifs);
    }
    
/*      TLineWrapper::ResultCollection results;
    Madou1MdLineWrapper(ifs, results, table, sizeTable, kerningMatrix)();
    
    if (results.size() > 0) {
      TOfstream ofs((outPrefix + "script_wrapped.txt").c_str());
      ofs.write(results[0].str.c_str(), results[0].str.size());
    } */
  }
  
  grpOfs.save((outPrefix + "-tiles.bin").c_str());
  
  return 0;
}

