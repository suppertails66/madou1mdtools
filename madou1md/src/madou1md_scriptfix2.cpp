#include "util/TStringConversion.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TThingyTable.h"
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

TThingyTable table;

void fixScript(TStream& src, TStream& ofs) {
  int lineNum = 0;
  
  while (!src.eof()) {
    std::string line;
    src.getLine(line);
    ++lineNum;
    
//    std::cerr << lineNum << std::endl;
//    if (line.size() <= 0) continue;
    if (line.size() <= 0) {
      ofs.put('\n');
      continue;
    }
    
    TBufStream ifs(line.size());
    ifs.write(line.c_str(), line.size());
    ifs.seek(0);
    
    // check for special stuff
    if (ifs.peek() == '#') {
      int pos = ifs.tell();
      string name;
      while (!ifs.eof() && (ifs.peek() != '(')) name += ifs.get();
      ifs.seek(pos);
      
      // copy directive to output
      while (!ifs.eof()) ofs.put(ifs.get());
      ofs.put('\n');
      continue;
    }
    
    while (!ifs.eof()) {
      // check for comments
      if ((ifs.remaining() >= 2)
          && (ifs.peek() == '/')) {
        ifs.get();
        if (ifs.peek() == '/') {
          ifs.unget();
          while (!ifs.eof()) ofs.put(ifs.get());
          break;
        }
        else ifs.unget();
      }
      
      // 2-byte sjis sequence
      if ((TByte)ifs.peek() >= 0x80) {
        ofs.put(ifs.get());
        ofs.put(ifs.get());
        continue;
      }
      
      if (ifs.peek() == '}') {
        ofs.put('{');
        ifs.get();
      }
      else if (ifs.peek() == '{') {
        ofs.put('}');
        ifs.get();
      }
      else {
        ofs.put(ifs.get());
      }
    }
    
    ofs.put('\n');
  }
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I (Mega Drive) script fixer 2" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [thingy] [outprefix]"
      << endl;
    
    return 0;
  }
  
  string inPrefix = string(argv[1]);
  string tableName = string(argv[2]);
  string outPrefix = string(argv[3]);
  
  table.readSjis(tableName);

  {
    TBufStream ifs;
    ifs.open((inPrefix + "temp.txt").c_str());
    
    TBufStream ofs;
    fixScript(ifs, ofs);
    ofs.save((outPrefix + "temp_fixed.txt").c_str());
  }
  
  return 0;
}

