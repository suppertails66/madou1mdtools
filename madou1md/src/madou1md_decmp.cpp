#include "md/Madou1MdCmp.h"
#include "util/TBufStream.h"
#include "util/TOpt.h"
#include "util/TStringConversion.h"
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Md;

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I graphics decompressor" << endl;
    cout << "Usage: "
         << argv[0] << " <infile> <headeroffset> <outfile> [options]" << endl;
    cout << "Options:" << endl;
    cout << "  --bigblocks     Flag: Use expanded default block sizes" << endl;
    cout << "  --mode          Specify compression mode (0/1)" << endl;
    
    return 0;
  }
  
  char* infile = argv[1];
  int headerOffset = TStringConversion::stringToInt(string(argv[2]));
  char* outfile = argv[3];
  
  bool expandedDefaultBlockSizes = false;
  if (TOpt::hasFlag(argc, argv, "--bigblocks"))
    expandedDefaultBlockSizes = true;
  
  Madou1MdCmpModes::Madou1MdCmpMode cmpMode
    = Madou1MdCmpModes::mode1;
  int modeArg = 1;
  TOpt::readNumericOpt(argc, argv, "--mode", &modeArg);
  if (modeArg == 1) cmpMode = Madou1MdCmpModes::mode1;
  else if (modeArg == 0) cmpMode = Madou1MdCmpModes::mode0;
  
  
  TBufStream ifs;
  ifs.open(infile);
  
  TBufStream ofs;
//  Madou1MdCmp::decmpFromHeader(ifs, headerOffset, ofs, expandedDefaultBlockSizes,
//                               true);
  Madou1MdDecompressor(
    ifs, headerOffset, ofs, cmpMode, expandedDefaultBlockSizes, true)();
  
  ofs.save(outfile);
  
  return 0;
} 
