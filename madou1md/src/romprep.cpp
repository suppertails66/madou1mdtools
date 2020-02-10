#include "util/TIfstream.h"
#include "util/TBufStream.h"
#include "util/TStringConversion.h"
#include <iostream>

using namespace std;
using namespace BlackT;

//int outputRomSize = 0x400000;

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I (MD) ROM prep tool" << endl;
    cout << "Usage: " << argv[0] << " <infile> <outromsize> <outfile>" << endl;
    
    return 0;
  }
  
  int outputRomSize = TStringConversion::stringToInt(std::string(argv[2]));
  
  TBufStream rom(outputRomSize);
  {
    TIfstream ifs(argv[1], ios_base::binary);
    rom.writeFrom(ifs, ifs.size());
  }
  int romend = rom.tell();
  
  // Pad to 4MB
  int padsize = outputRomSize - romend;
  rom.seek(romend);
  // Pad to 2MB
//  int padsize = 0x200000 - romend;
//  rom.seek(romend);
  // oops i haven't implemented memset for tbufstream
  for (int i = 0; i < padsize; i++) {
    char c = 0;
    rom.write(&c, 1);
  }
  int romsize = rom.tell();
  
  // Recompute checksum
  rom.seek(0x200);
  unsigned short int sum = 0;
  while (rom.tell() < romsize) {
    sum += (unsigned short int)(rom.readu16be());
//    cout << hex << sum << endl;
//    char c; cin >> c;
  }
  rom.seek(0x18E);
  rom.writeu16be(sum);
  
  // update rom end field
  rom.seek(0x1A4);
  rom.writeu32be(outputRomSize - 1);
  
  rom.seek(romsize);
  rom.save(argv[3]);
  
  return 0;
}
