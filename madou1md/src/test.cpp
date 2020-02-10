#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TSoundFile.h"
#include <vector>
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Sms;

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

int main(int argc, char* argv[]) {
  TThingyTable table;
  table.readSjis("table/madou1md.tbl");
  
  std::cout << table.entries.size() << std::endl;
  
  return 0;
}
