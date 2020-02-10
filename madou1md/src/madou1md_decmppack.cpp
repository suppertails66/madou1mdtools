#include "md/Madou1MdCmp.h"
#include "util/TBufStream.h"
#include "util/TOpt.h"
#include "util/TStringConversion.h"
#include "util/TByte.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Md;

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I graphics pack decompressor" << endl;
    cout << "Usage: "
         << argv[0] << " <infile> <headeroffset> <outprefix> [options]" << endl;
    cout << "Options:" << endl;
    cout << "  --bigblocks     Use expanded default block sizes" << endl;
    cout << "  --asvram        Unpacks to a complete VRAM layout" << endl;
    
    return 0;
  }
  
  char* infile = argv[1];
  int headerOffset = TStringConversion::stringToInt(string(argv[2]));
  string outprefix = argv[3];
  
  bool expandedDefaultBlockSizes = false;
  if (TOpt::hasFlag(argc, argv, "--bigblocks"))
    expandedDefaultBlockSizes = true;
  
  bool asVram = false;
  if (TOpt::hasFlag(argc, argv, "--asvram"))
    asVram = true;
  
  TBufStream ifs;
  ifs.open(infile);
  
  TBufStream vram;
  if (asVram) vram.padToSize(0x10000, 0x00);
  
  ifs.seek(headerOffset);
  int num = 0;
  while ((TByte)ifs.peek() != 0xFF) {
    if (ifs.peek() == 0xFE) {
      ifs.seekoff(6);
      continue;
    }
    
    int base = ifs.tell();
    
    TBufStream ofs;
    
    Madou1MdPackDecompressor(
      ifs, base, ofs, expandedDefaultBlockSizes, true)();
    
    ifs.seek(base + 4);
    int dstAddr = ifs.readu16be();
    
    if (asVram) {
      vram.seek(dstAddr);
      ofs.seek(0);
      vram.writeFrom(ofs, ofs.size());
    }
    else {
      ofs.save(
        (outprefix
          + TStringConversion::intToString(num)
          + "-"
          + TStringConversion::intToString(dstAddr,
              TStringConversion::baseHex)
          + ".bin").c_str());
    }
    
    ifs.seek(base + 6);
    ++num;
  }
  
  if (asVram)
    vram.save(
      (outprefix + "vram.bin").c_str());
  
  return 0;
} 
