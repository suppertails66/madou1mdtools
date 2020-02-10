#include "util/TThingyTable.h"
#include "util/TStringConversion.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TOpt.h"
#include "exception/TGenericException.h"
#include <string>
#include <fstream>
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Md;


/*void printScript(TStream& ifs, ofstream& ofs, const TThingyTable& thingy) {
  ofs << "// $" << TStringConversion::intToString(ifs.tell(),
                      TStringConversion::baseHex).substr(2, string::npos)
    << endl;
  while (!ifs.eof()) {
    int next = (unsigned char)ifs.get();
    if (thingy.hasEntry(next)) {
      ofs << thingy.getEntry(next);
      
      // stop at terminator
      if (next == 0x00) {
        ofs << endl << endl;
        return;
      }
    }
    else {
      throw TGenericException(T_SRCANDLINE,
                              "printScript()",
                              "Invalid script character at "
                                + TStringConversion::intToString(
                                    ifs.tell()));
    }
  }
} */

int main(int argc, char* argv[]) {
/*  if (argc < 4) {
    cout << "Binary -> text converter, via Thingy table" << endl;
    cout << "Usage: " << argv[0] << " <thingy> <rom> <outfile>"
      << endl;
    cout << "The Thingy table must be in SJIS (or compatible) format."
      << endl;
    cout << "Note that only one-byte encoding sequences are supported."
      << endl;
    
    return 0;
  }
  
  TThingyTable thingy;
  thingy.readSjis(string(argv[1]));
  NesRom rom = NesRom(string(argv[2]));
//  int offset = TStringConversion::stringToInt(argv[3]);
  TBufStream ifs(rom.size());
  ifs.write((char*)rom.directRead(0), rom.size());
//  std::ifstream ifs(argv[2], ios_base::binary);
  std::ofstream ofs(argv[3], ios_base::binary);
  
  ifs.seek(pointerTableStart);
  int bankNum
    = UxRomBanking::directToBankNumMovable(pointerTableStart);
  
  for (int i = 0; i < numPointerTableEntries; i++) {
    int pointer = ifs.readu16le();
    int nextPos = ifs.tell();
    int physicalPointer
      = UxRomBanking::bankedToDirectAddressMovable(bankNum, pointer);
    
    ifs.seek(physicalPointer);
    printScript(ifs, ofs, thingy);
    
    ifs.seek(nextPos);
  }
  
//  while (ifs.good()) {
//    int next = (unsigned char)ifs.get();
//    if (thingy.hasEntry(next)) {
//      ofs << thingy.getEntry(next);
//      
//      if (next == 0x00) ofs << endl;
//    }
//  } 
  
  return 0; */

  if (argc < 4) {
    cout << "Binary -> text converter, via Thingy table" << endl;
    cout << "Usage: " << argv[0] << " <thingy> <infile> <outfile>"
      << " [options]" << endl;
    cout << "The Thingy table must be in SJIS (or compatible) format."
      << endl;
    cout << "Options:" << endl;
    cout << "  -b     Force N bytes per character. Default is automatic."
      << endl;
    
    return 0;
  }
  
  TThingyTable thingy;
  thingy.readSjis(string(argv[1]));
//  std::ifstream ifs(argv[2], ios_base::binary);

//  TIfstream ifs(argv[2], ios_base::binary);

  TBufStream ifs(1);
  ifs.open(argv[2]);
  ifs.seek(0);

//  std::ofstream ofs(argv[3], ios_base::binary);
  TBufStream ofs;
  
  int bytesPerChar = -1;
  TOpt::readNumericOpt(argc, argv, "-b", &bytesPerChar);
  
  while (!ifs.eof()) {
//    int next = (unsigned char)ifs.get();
    TThingyTable::MatchResult result = thingy.matchId(ifs, bytesPerChar);
    
    if (result.id != -1) {
//      ofs << thingy.getEntry(result.id);
      std::string resultStr = thingy.getEntry(result.id);
      ofs.write(resultStr.c_str(), resultStr.size());
    }
    else {
//      ofs << "?";
      ofs.put('?');
      ifs.get();
    }
      
    if ((ifs.tell() % 0x40) == 0) {
//      ofs << std::endl;
      ofs.put('\n');
//      ofs << "// $" << std::hex << ifs.tell() << std::endl;
      std::string label;
      label += "// $";
      label += TStringConversion::intToString(ifs.tell(),
        TStringConversion::baseHex).substr(2, std::string::npos);
      label += '\n';
      ofs.write(label.c_str(), label.size());
    }
  }
  
  ofs.save(argv[3]);
  
/*  for (int i = 0; i < 521; i++) {
    string left
      = TStringConversion::intToString(i, TStringConversion::baseHex);
    left = left.substr(2, string::npos);
    cout << left << "=？" << std::endl;
  } */
  
  return 0; 
}
