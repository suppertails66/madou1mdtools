#include "util/TStringConversion.h"
#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TThingyTable.h"
#include "exception/TGenericException.h"
#include <string>
#include <map>
#include <fstream>
#include <sstream>
#include <iostream>

using namespace std;
using namespace BlackT;

bool verbose = false;

const static int op_end        = 0xFF04;
const static int op_delay      = 0xFF0C;
const static int op_leftbox1    = 0xFF10;
const static int op_rightbox1   = 0xFF14;
const static int op_leftbox2    = 0xFF18;
const static int op_rightbox2   = 0xFF1C;
const static int op_centerbox28   = 0xFF28;
const static int op_centerbox2C   = 0xFF2C;
const static int op_br         = 0xFF30;
const static int op_wait       = 0xFF34;
const static int op_autoend    = 0xFF38;
const static int op_buffer1char    = 0xFF44;
const static int op_buffer2char    = 0xFF48;
const static int op_buffer5char    = 0xFF4C;
const static int op_voice50       = 0xFF50;
const static int op_arleanim       = 0xFF54;
const static int op_anim       = 0xFF58;
const static int op_op5C       = 0xFF5C;
const static int op_openleftbox   = 0xFF60;
const static int op_closeleftbox  = 0xFF64;
const static int op_openrightbox  = 0xFF68;
const static int op_closerightbox = 0xFF6C;
const static int op_prompt70      = 0xFF70;
const static int op_prompt74      = 0xFF74;
const static int op_buffer7char    = 0xFF78;
const static int op_prompt7C      = 0xFF7C;
const static int op_maplabel   = 0xFF80;
const static int op_face       = 0xFF84;
const static int op_op88       = 0xFF88;
const static int op_op8C       = 0xFF8C;
const static int op_op90       = 0xFF90;
const static int op_op94       = 0xFF94;
const static int op_op98       = 0xFF98;
const static int op_prompt9C       = 0xFF9C;
const static int op_promptA0       = 0xFFA0;
const static int op_promptA4       = 0xFFA4;
const static int op_promptA8       = 0xFFA8;
const static int op_opAC       = 0xFFAC;
const static int op_resetface       = 0xFFB0;
const static int op_opB4       = 0xFFB4;
const static int op_opC0_end   = 0xFFC0;
const static int op_voiceC4       = 0xFFC4;
const static int op_opC8       = 0xFFC8;
const static int op_opCC       = 0xFFCC;
const static int op_opD4       = 0xFFD4;
const static int op_opD8       = 0xFFD8;
const static int op_opDC       = 0xFFDC;
const static int op_opE0       = 0xFFE0;
const static int op_opE4       = 0xFFE4;
const static int op_opE8       = 0xFFE8;
const static int op_opEC       = 0xFFEC;
const static int op_opF0       = 0xFFF0;
const static int op_terminator = 0xFFFF;

static int totalScriptNum = 0;
static std::map<int, int> seenAddresses;

string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
  return "<$" + str + ">";
}

string as4bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 4) str = string("0") + str;
  
  return "<$" + str + ">";
}

void addComment(std::ostream& ofs, string comment) {
  ofs << "//===========================================================" << endl;
  ofs << "// " << comment << endl;
  ofs << "//===========================================================" << endl;
  ofs << endl;
}

void addSubComment(std::ostream& ofs,
               string comment = "") {
  if (comment.size() > 0) {
    ofs << "//=======================================" << endl;
    ofs << "// " << comment << endl;
    ofs << "//=======================================" << endl;
    ofs << endl;
  }
}

/*void dumpScript(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                int scriptOffset) {
  // have we already dumped this script?
  std::map<int, int>::iterator findIt = seenAddresses.find(scriptOffset);
  if (findIt != seenAddresses.end()) {
    ofs << "// NOTE: skipping previously dumped script at "
      << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
      << std::endl << std::endl;
    ifs.seek(findIt->second);
    return;
  }
  
  ofs << "#STARTSCRIPT("
    << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
    << ")" << std::endl << std::endl;
  
  // assume ifs is already at the correct input position
  
  std::ostringstream oss;
  
  bool atLineStart = true;
  while (!ifs.eof()) {
    TThingyTable::MatchResult result = table.matchId(ifs, 2);
    if (result.id == -1) {
      throw TGenericException(T_SRCANDLINE,
                              "dumpScript()",
                              string("At file offset ")
                                + TStringConversion::intToString(
                                    ifs.tell(),
                                    TStringConversion::baseHex)
                                + ": could not match character from table");
    }
    
    int id = result.id;
    string resultStr = table.getEntry(result.id);
    
    if (!atLineStart
        && ((id == op_leftbox1)
            || (id == op_rightbox1)
            || (id == op_leftbox2)
            || (id == op_rightbox2)
            || (id == op_centerbox28)
            || (id == op_centerbox2C)
            || (id == op_maplabel))) {
      oss << std::endl << std::endl;
    }
    
    oss << resultStr;
    
    atLineStart = false;
    
    // ops with a param word
    if ((id == op_delay)
        || (id == op_voice50)
        || (id == op_arleanim)
        || (id == op_anim)
        || (id == op_op5C)
        || (id == op_face)
        || (id == op_op88)
        || (id == op_op8C)
        || (id == op_op90)
        || (id == op_op94)
        || (id == op_op98)
        || (id == op_opAC)
        || (id == op_voiceC4)
        || (id == op_opC8)
        ) {
      oss << as4bHex(ifs.readu16be());
    }
    else if (id == op_br) {
      oss << std::endl;
      atLineStart = true;
    }
    else if ((id == op_wait)) {
      oss << std::endl << std::endl;
      atLineStart = true;
    }
    // some kind of wait?
    else if ((id == op_opB4)) {
      oss << std::endl << std::endl;
      atLineStart = true;
    }
    else if ((id == op_leftbox1)
             || (id == op_rightbox1)
             || (id == op_leftbox2)
             || (id == op_rightbox2)
             || (id == op_centerbox28)
             || (id == op_centerbox2C)
             || (id == op_maplabel)) {
      oss << std::endl;
      atLineStart = true;
    }
    else if ((id == op_end)
             || (id == op_autoend)
             || (id == op_opC0_end)) {
      break;
    }
    else if ((id == op_terminator)) {
      break;
    }
  }
  
  // crude hack to remove blank comment lines.
  // doesn't work with windows linebreaks.
  {
    std::string oldstr = oss.str();
    std::string newstr;
    int i = 0;
    while (i < oldstr.size() - 5) {
      if (oldstr.substr(i, 5).compare("// \n\n") == 0) {
        i += 5;
      }
      else {
        newstr += oldstr[i];
        ++i;
      }
    }
    newstr += oldstr.substr(oldstr.size() - 5, 5);
    oss.str(newstr);
  }
  
  ofs << oss.str();
  ofs << std::endl << std::endl;
  
  ofs << "// endpos: "
    << TStringConversion::intToString(ifs.tell(), TStringConversion::baseHex)
    << std::endl;
    
  
  // have we seen this data before?
  int endScriptOffset = ifs.tell();
  bool alreadySeen = false;
  std::map<int, int>::iterator matchIt = seenAddresses.end();
  for (std::map<int, int>::iterator it = seenAddresses.begin();
       it != seenAddresses.end();
       ++it) {
//      std::cerr << num++ << " " << it->first << " " << std::hex << it->second << std::endl;
    int startAddr = it->first;
    int endAddr = it->second;
    if (((scriptOffset >= startAddr) && (scriptOffset < endAddr))
        || ((startAddr >= scriptOffset) && (startAddr < endScriptOffset))
        ) {
      matchIt = it;
      ofs << "// WARNING: Script overlap!" << std::endl;
      ofs << "//  First seen at: "
        << TStringConversion::intToString(startAddr, TStringConversion::baseHex)
        << "-"
        << TStringConversion::intToString(endAddr, TStringConversion::baseHex)
        << std::endl;
      ofs << "//  Now seen at: "
        << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
        << "-"
        << TStringConversion::intToString(endScriptOffset, TStringConversion::baseHex)
        << std::endl << std::endl;
      alreadySeen = true;
      break;
    }
  }
  
  if (!alreadySeen) {
    seenAddresses[scriptOffset] = endScriptOffset;
  }
  else if (alreadySeen && (matchIt->first >= scriptOffset)) {
    // if this script is larger than the old one, expand the marked area
    seenAddresses.erase(matchIt);
    seenAddresses[scriptOffset] = endScriptOffset;
  }
  
  ofs << "#ENDSCRIPT()" << std::endl << std::endl;
  ++totalScriptNum;
} */

int numOpParamWords(int op) {
  switch (op) {
  case op_delay:
  case op_voice50:
  case op_arleanim:
  case op_anim:
  case op_op5C:
  case op_face:
  case op_op88:
  case op_op8C:
  case op_op90:
  case op_op94:
  case op_op98:
  case op_opAC:
  case op_voiceC4:
  case op_opC8:
    return 1;
    break;
  default:
    break;
  }
  
  return 0;
}

bool isSharedOp(int op) {
/*  if (numOpParamWords(op) > 0) return true;
  
  switch (op) {
  case op_end:
  case op_leftbox1:
  case op_rightbox1:
  case op_leftbox2:
  case op_rightbox2:
  case op_centerbox28:
  case op_centerbox2C:
  case op_wait:
  case op_autoend:
  case op_maplabel:
  case op_prompt70:
  case op_promptA0:
  case op_opB4:
  case op_opC0_end:
  case op_opCC:
  case op_terminator:
  case op_openleftbox:
  case op_closeleftbox:
  case op_openrightbox:
  case op_closerightbox:
  case op_face:
  case op_resetface:
  case op_anim:
  case op_arleanim:
    return true;
    break;
  default:
    break;
  }
  
  return false; */
  
  // you know what, trying to exhaustively list every shared op
  // is pretty damn stupid when there are maybe three that aren't
  // shared
  switch (op) {
  case op_br:
  case op_buffer1char:
  case op_buffer2char:
  case op_buffer5char:
  case op_buffer7char:
  case op_opD4:
  case op_opD8:
  case op_opDC:
  case op_opE0:
  case op_opE4:
  case op_opE8:
  case op_opEC:
  case op_opF0:
    return false;
    break;
  default:
    break;
  }
  
  return true;
}

// number of linebreaks that should precede an op type
int numOpPreLines(int op) {
  switch (op) {
  case op_wait:
  case op_prompt70:
  case op_prompt74:
  case op_prompt7C:
  case op_prompt9C:
  case op_promptA0:
  case op_promptA4:
  case op_promptA8:
  case op_leftbox1:
  case op_leftbox2:
  case op_rightbox1:
  case op_rightbox2:
    return 1;
    break;
/*  case op_leftbox1:
  case op_rightbox1:
  case op_leftbox2:
  case op_rightbox2:
  case op_centerbox28:
  case op_centerbox2C:
  case op_maplabel:
    return 2;
    break; */
  default:
    break;
  }
  
  return 0;
}

// number of linebreaks that should follow an op type
int numOpPostLines(int op) {
/*  if (numOpParamWords(op) > 0) return 1;
  
  switch (op) {
  case op_br:
  case op_leftbox1:
  case op_rightbox1:
  case op_leftbox2:
  case op_rightbox2:
  case op_centerbox28:
  case op_centerbox2C:
  case op_maplabel:
  case op_openleftbox:
  case op_closeleftbox:
  case op_openrightbox:
  case op_closerightbox:
  case op_resetface:
  case op_face:
    return 1;
    break;
  case op_wait:
  case op_opB4:
  case op_end:
  case op_autoend:
  case op_opC0_end:
  case op_terminator:
    return 2;
    break;
  default:
    break;
  }
  
  if (isSharedOp(op)) return 1;
  
  return 0; */
  
  switch (op) {
  case op_br:
    return 1;
    break;
  case op_wait:
  case op_opB4:
  case op_end:
  case op_autoend:
  case op_opC0_end:
  case op_terminator:
    return 2;
    break;
  default:
    break;
  }
  
  if (isSharedOp(op)) return 1;
  
  return 0;
}

void dumpScript(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                int scriptOffset) {
  // have we already dumped this script?
  std::map<int, int>::iterator findIt = seenAddresses.find(scriptOffset);
  if (findIt != seenAddresses.end()) {
    if (verbose) {
      ofs << "// NOTE: skipping previously dumped script at "
        << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
        << std::endl << std::endl;
    }
    ifs.seek(findIt->second);
    return;
  }
  
  ofs << "#STARTSCRIPT("
    << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
    << ")" << std::endl << std::endl;
  
  // assume ifs is already at the correct input position
  
  std::ostringstream oss_final;
  std::ostringstream oss_textline;
  
  bool atLineStart = true;
  bool lastWasBr = false;
  while (!ifs.eof()) {
    TThingyTable::MatchResult result = table.matchId(ifs, 2);
    if (result.id == -1) {
      throw TGenericException(T_SRCANDLINE,
                              "dumpScript()",
                              string("At file offset ")
                                + TStringConversion::intToString(
                                    ifs.tell(),
                                    TStringConversion::baseHex)
                                + ": could not match character from table");
    }
    
    int id = result.id;
    string resultStr = table.getEntry(result.id);
    bool isOp = (id >= 0xFF00);
    
    if (isOp) {
      bool shared = isSharedOp(id);
      
      std::ostringstream* targetOss = NULL;
      if (shared) {
        targetOss = &oss_final;
        
        // empty comment line buffer
        if (oss_textline.str().size() > 0) {
          oss_final << "// " << oss_textline.str();
          oss_final << std::endl << std::endl;
          oss_textline.str("");
          atLineStart = true;
        }
      }
      else {
        targetOss = &oss_textline;
      }
      
      //===========================================
      // output pre-linebreaks
      //===========================================
      
      int numPreLines = numOpPreLines(id);
      if ((!atLineStart || (atLineStart && lastWasBr))
          && (numPreLines > 0)) {
        if (oss_textline.str().size() > 0) {
          oss_final << "// " << oss_textline.str();
          oss_textline.str("");
        }
        
        for (int i = 0; i < numPreLines; i++) {
          oss_final << std::endl;
        }

        atLineStart = true;
      }
      
      //===========================================
      // if op is shared, output it directly to
      // the final text on its own line, separate
      // from the commented-out original
      //===========================================
      
      // non-shared op: add to commented-out original line
      *targetOss << resultStr;
      atLineStart = false;
      
      //===========================================
      // output param words
      //===========================================
      
      int numParamWords = numOpParamWords(id);
      for (int i = 0; i < numParamWords; i++) {
        *targetOss << as4bHex(ifs.readu16be());
        atLineStart = false;
      }
      
      //===========================================
      // output post-linebreaks
      //===========================================
     
      int numPostLines = numOpPostLines(id);
      if (numPostLines > 0) {
        if (oss_textline.str().size() > 0) {
          oss_final << "// " << oss_textline.str();
          oss_textline.str("");
        }
       
        for (int i = 0; i < numPostLines; i++) {
          oss_final << std::endl;
        }

        atLineStart = true;
      }
    }
    else {
     // not an op: add to commented-out original line
      oss_textline << resultStr;
      
      atLineStart = false;
    }
    
    // check for terminators
    if ((id == op_end)
             || (id == op_autoend)
             || (id == op_opC0_end)) {
      break;
    }
    else if ((id == op_terminator)) {
      break;
    }
    
    lastWasBr = (id == op_br);
  }
  
  // crude hack to remove blank comment lines.
  // doesn't work with windows linebreaks.
/*  {
    std::string oldstr = oss.str();
    std::string newstr;
    int i = 0;
    while (i < oldstr.size() - 5) {
      if (oldstr.substr(i, 5).compare("// \n\n") == 0) {
        i += 5;
      }
      else {
        newstr += oldstr[i];
        ++i;
      }
    }
    newstr += oldstr.substr(oldstr.size() - 5, 5);
    oss.str(newstr);
  } */
  
  ofs << oss_final.str();
//  ofs << std::endl << std::endl;
  
  if (verbose) {
    ofs << "// endpos: "
      << TStringConversion::intToString(ifs.tell(), TStringConversion::baseHex)
      << std::endl;
  }
    
  
  // have we seen this data before?
  int endScriptOffset = ifs.tell();
  bool alreadySeen = false;
  std::map<int, int>::iterator matchIt = seenAddresses.end();
  for (std::map<int, int>::iterator it = seenAddresses.begin();
       it != seenAddresses.end();
       ++it) {
//      std::cerr << num++ << " " << it->first << " " << std::hex << it->second << std::endl;
    int startAddr = it->first;
    int endAddr = it->second;
    if (((scriptOffset >= startAddr) && (scriptOffset < endAddr))
        || ((startAddr >= scriptOffset) && (startAddr < endScriptOffset))
        ) {
      matchIt = it;
      if (verbose) {
        ofs << "// WARNING: Script overlap!" << std::endl;
        ofs << "//  First seen at: "
          << TStringConversion::intToString(startAddr, TStringConversion::baseHex)
          << "-"
          << TStringConversion::intToString(endAddr, TStringConversion::baseHex)
          << std::endl;
        ofs << "//  Now seen at: "
          << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
          << "-"
          << TStringConversion::intToString(endScriptOffset, TStringConversion::baseHex)
          << std::endl << std::endl;
      }
      alreadySeen = true;
      break;
    }
  }
  
  if (!alreadySeen) {
    seenAddresses[scriptOffset] = endScriptOffset;
  }
  else if (alreadySeen && (matchIt->first >= scriptOffset)) {
    // if this script is larger than the old one, expand the marked area
    seenAddresses.erase(matchIt);
    seenAddresses[scriptOffset] = endScriptOffset;
  }
  
  ofs << "#ENDSCRIPT()" << std::endl << std::endl;
  ++totalScriptNum;
}

void dumpScriptPos(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                   int scriptOffset) {
  ifs.seek(scriptOffset);
  dumpScript(ifs, ofs, table, scriptOffset);
}

void dumpScriptsAtPos(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                   int scriptOffset, int numScripts) {
  ifs.seek(scriptOffset);
  if (verbose) {
    addComment(ofs, std::string("Dumping script block at ")
      + TStringConversion::intToString(scriptOffset, TStringConversion::baseHex));
  }
  for (int i = 0; i < numScripts; i++) {
    if (verbose) {
      ofs << "// script "
        << TStringConversion::intToString(scriptOffset, TStringConversion::baseHex)
        << "-"
        << TStringConversion::intToString(i, TStringConversion::baseHex)
        << std::endl << std::endl;
    }
      
    dumpScript(ifs, ofs, table, ifs.tell());
  }
}

void dumpScriptsAtCurPos(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                   int numScripts) {
  dumpScriptsAtPos(ifs, ofs, table, ifs.tell(), numScripts);
}

void dumpScriptOffsetTable(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                   int tableAddress, int numScripts,
                   int baseAddressOverride = -1) {
//  dumpScriptsAtPos(ifs, ofs, table, ifs.tell(), numScripts);
  
  // sort source addresses
  ifs.seek(tableAddress);
  std::map<int, int> addresses;
  for (int i = 0; i < numScripts; i++) {
    int offset = ifs.readu16be();
    int address = offset + tableAddress;
    if (baseAddressOverride != -1) address = offset + baseAddressOverride;
    addresses[address] = i;
  }
  
  for (std::map<int, int>::iterator it = addresses.begin();
       it != addresses.end();
       ++it) {
    if (verbose) {
      ofs << "// script offset table entry "
        << TStringConversion::intToString(tableAddress, TStringConversion::baseHex)
        << "-"
        << TStringConversion::intToString(it->second, TStringConversion::baseHex)
        << std::endl << std::endl;
    }
    int address = it->first;
    dumpScriptPos(ifs, ofs, table, address);
  }
  
/*  for (int i = 0; i < numScripts; i++) {
    ofs << "// script offset table entry "
      << TStringConversion::intToString(tableAddress, TStringConversion::baseHex)
      << "-"
      << TStringConversion::intToString(i, TStringConversion::baseDec)
      << std::endl << std::endl;
    
    ifs.seek(tableAddress + (i * 2));
    int offset = ifs.readu16be();
    int address = tableAddress + offset;
    dumpScriptPos(ifs, ofs, table, address);
  } */
}

void autoDumpScriptOffsetTable(TStream& ifs, std::ostream& ofs, TThingyTable& table,
                   int tableAddress) {
//  dumpScriptsAtPos(ifs, ofs, table, ifs.tell(), numScripts);
  ifs.seek(tableAddress);
  // assume first entry is first script
  int offset = ifs.readu16be();
  int numScripts = offset / 2;
  
  dumpScriptOffsetTable(ifs, ofs, table, tableAddress, numScripts);
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Madou Monogatari I (Mega Drive) script dumper" << endl;
    cout << "Usage: " << argv[0] << " [rom] [outprefix]" << endl;
    
    return 0;
  }
  
  string romName = string(argv[1]);
//  string tableName = string(argv[2]);
  string outPrefix = string(argv[2]);
  
  TBufStream ifs;
  ifs.open(romName.c_str());
  
  TThingyTable tablestd;
  tablestd.readSjis(string("table/madou1md.tbl"));
  
  try
  {
    std::ofstream ofs((outPrefix + "script.txt").c_str(),
                  ios_base::binary);
    
    // stuff
    addComment(ofs, "miscellaneous/system messages");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9E210, 0x28);
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9E264, 13);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9E260, 0xD);
    
    // 0x9E4B2 = offset table (0xA entries)
    // spell commands
    addComment(ofs, "spell command list");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9E4C6, 10);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9E4B2, 0xA);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9E4C6, 0xA);
    
    // more stuff
//    dumpScriptsAtCurPos(ifs, ofs, tablestd, 29);
    
    // 0x9ECDC = offset table (0x20 entries, 28 valid) to enemy names.
    // TODO:
    // these are not scripts, but an array of 6-character strings padded with
    // spaces.
    // except not all of them are 6 characters.
    // this is really stupid.
    // anyway, they go until 0x9ee48?
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9ED1C, 0x20);
    {
      std::ofstream ofs((outPrefix + "monsters.txt").c_str(),
                    ios_base::binary);
      addComment(ofs, "monster names");
      for (int i = 0; i < 28; i++) {
        addSubComment(ofs, "monster name " + TStringConversion::intToString(i));
        
        ifs.seek(0x9ECDC + (i * 2));
        int offset = ifs.readu16be();
        int addr = 0x9ECDC + offset;
        ifs.seek(addr);
        ofs << "#STARTSCRIPT("
          << TStringConversion::intToString(addr, TStringConversion::baseHex)
          << ")" << std::endl;
        ofs << endl;
        ofs << "// ";
        for (int j = 0; j < 6; j++) {
          TThingyTable::MatchResult result = tablestd.matchId(ifs, 2);
          if (result.id == -1) {
            throw TGenericException(T_SRCANDLINE,
                                    "dumpScript()",
                                    string("At file offset ")
                                      + TStringConversion::intToString(
                                          ifs.tell(),
                                          TStringConversion::baseHex)
                           + ": could not match enemy name character from table");
          }
          ofs << tablestd.getEntry(result.id);
        }
        ofs << endl;
        ofs << endl;
        ofs << endl;
        ofs << "#ENDSCRIPT()" << std::endl;
        ofs << endl;
      }
    }

    // 0x9EE48 = offset table (0x10 entries) for battle health messages
    addComment(ofs, "arle health messages?");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9EE68, 0x10);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9EE48, 0x10);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9EE68, 0x10);
    
    // 0x9F148 = offset table (0x8 entries) for ?
    addComment(ofs, "arle mp restore messages");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F158, 0x8);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9F148, 0x8);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F158, 0x8);
    
    // 0x9F26E = offset table (0x8 entries) for battle mp messages
    addComment(ofs, "arle mp remaining messages");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F27E, 0x8);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9F26E, 0x8);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F27E, 0x8);
    
    // 0x9F424 = offset table (0x8 entries) for ?
    addComment(ofs, "arle hp restore messages");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F434, 0x8);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9F424, 0x8);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F434, 0x8);
    
    // 0x9F570 = offset table (0x8 entries) for ?
    addComment(ofs, "arle hp/mp restore messages");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F580, 0x8);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9F570, 0x8);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F580, 0x8);
    
    // 0x9F6EC = offset table (0x17 entries) for ?
    // NOTE: some of these point to scripts that follow
    // the next offset table. there are actually only 16 scripts in this block.
    addComment(ofs, "arle damage taken messages");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F71A, 16);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9F6EC, 0x17);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F71A, 0x10);
    
    // 0x9F972 = offset table (0x17 entries) for ?
    addComment(ofs, "arle damage taken messages, without voice clips?");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F9A0, 0x17);
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9F972, 0x17);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9F9A0, 0x17);
    
/*    int baseaddr = 0x9FC80;
    ifs.seek(baseaddr);
    std::map<int, int> test;
    for (int i = 0; i < 0x4B; i++) {
      int offset = ifs.readu16be();
      int addr = offset + baseaddr;
      test[offset] = addr;
    }
    int num = 0;
    for (std::map<int, int>::iterator it = test.begin();
         it != test.end();
         ++it) {
      std::cerr << num++ << " " << it->first << " " << std::hex << it->second << std::endl;
    } */
    
    // 0x9FC80 = offset table (0x4B entries) for ?
    addComment(ofs, "arle spell messages");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0x9FC80, 0x4B);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0x9FD16, 0x43);
    
    addComment(ofs, "item names");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA08C6, 0x34);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA092E, 0x28);
    
    addComment(ofs, "items names, now with quotation marks");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA0AEC, 0x34);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA0B54, 0x28);
    
//    addComment(ofs, "?");
//    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA0E12, 0x94);
    
    // three consecutive offset tables all pointing into the same block
    addComment(ofs, "item descriptions");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA0E12, 39);
    addComment(ofs, "item use messages?");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA0E7A, 51);
    addComment(ofs, "item use messages 2?");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA0EE0, 45);
    // dump raw block
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA0F3A, 133);
    
    addComment(ofs, "enemy health messages?");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA26B6, 0x10);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA26D6, 0x10);
    
    addComment(ofs, "enemy damage messages?");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA299E, 0x8);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA29AE, 8);
    
    // enemy encounter messages?
    addComment(ofs, "enemy encounter messages");
    for (int i = 0; i < 0x20; i++) {
      addSubComment(ofs,
        std::string("enemy ")
          + TStringConversion::intToString(i)
          + " encounter message");
      ifs.seek(0x9E0F0 + (i * 4));
      int address = ifs.readu32be();
      dumpScriptPos(ifs, ofs, tablestd, address);
    }
    
    // enemy battle messages?
    addComment(ofs, "enemy battle messages");
//    for (int i = 0; i < 0x1C; i++) {
    for (int i = 0; i < 24; i++) {
      addSubComment(ofs,
        std::string("enemy ")
          + TStringConversion::intToString(i)
          + " battle messages");
      
      // special-case enemies with poorly-formatted tables where the first
      // entry is not to the first string in the data
      if (i == 22) {
        // "FF60FF04" appears at start of data but is skipped by offset table
        dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA4BB6, 8);
      }
      else {
        ifs.seek(0x9E194 + (i * 4));
        int address = ifs.readu32be();
        autoDumpScriptOffsetTable(ifs, ofs, tablestd, address);
      }
    }
    
    addComment(ofs, "enemy 24??");
    dumpScriptPos(ifs, ofs, tablestd, 0xA4DEE);
    addComment(ofs, "enemy 25??");
    dumpScriptPos(ifs, ofs, tablestd, 0xA4E90);
    
    addComment(ofs, "enemy 26??");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA4F60, 8);
    addComment(ofs, "enemy 27??");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA391A, 8);
    
    // encounter messages
//    addComment(ofs, "puyo messages?");
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA2A74, 5);
    
    // offset table of green puyo messages?
//    addComment(ofs, "puyo messages 2?");
//    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA2B24, 0x10);
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA2B44, 0x10);
    
    addComment(ofs, "generic enemy?");
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA4F40, 1);
    
    // A5040 = ?
    
    // dungeon scripts? for each floor?
    // table at 0xA505C (0x12 entries) contains pointers to offset tables
    
    addComment(ofs, "dungeon messages");
    for (int i = 0; i < 0x12; i++) {
      addComment(ofs,
        std::string("dungeon ")
          + TStringConversion::intToString(i));
      
      ifs.seek(0xA505C + (i * 4));
      int offsetTableAddr = ifs.readu32be();
      
      ifs.seek(offsetTableAddr);
      int firstOffset = ifs.readu16be();
      int numPhysicalEntries = firstOffset / 2;
      
      switch (i) {
      case 1: numPhysicalEntries = 36; break;
      case 4: numPhysicalEntries = 21; break;
      case 5: numPhysicalEntries = 26; break;
      case 7: numPhysicalEntries = 20; break;
      case 8: numPhysicalEntries = 30; break;
      case 9: numPhysicalEntries = 29; break;
      case 10: numPhysicalEntries = 32; break;
      case 11: numPhysicalEntries = 21; break;
      case 12: numPhysicalEntries = 16; break;
      case 13: numPhysicalEntries = 16; break;
      case 15: numPhysicalEntries = 13; break;
      case 16: numPhysicalEntries = 21; break;
      case 17: numPhysicalEntries = 21; break;
      default:
        break;
      }
      
      // exceptions
      if (i == 0) {
        // first entry is not start of data
        dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA50A4, 0x2B);
        dumpScriptsAtPos(ifs, ofs, tablestd, 0xA50FA, 40);
      }
      else if (i == 6) {
        // table entries 7/8 are invalid (point to next block's offset table)
        dumpScriptOffsetTable(ifs, ofs, tablestd, 0xAAC38, 7);
        dumpScriptOffsetTable(ifs, ofs, tablestd, 0xAAC48, 0xA,
                              0xAAC38);
        dumpScriptsAtPos(ifs, ofs, tablestd, 0xAAC5C, 15);
        
      }
//      else if (i == 1) {
//        dumpScriptOffsetTable(ifs, ofs, tablestd, 0xa6390, 0x4c/2);
//        dumpScriptsAtPos(ifs, ofs, tablestd, 0xa63dc, 36);
//      }
//      else if (i == 4) {
//        dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA9208, 0x2C/2);
//        dumpScriptsAtPos(ifs, ofs, tablestd, 0xa63dc, 21);
//      }
      else {
//        ifs.seek(offsetTableAddr);
        
        autoDumpScriptOffsetTable(ifs, ofs, tablestd, offsetTableAddr);
        dumpScriptsAtPos(ifs, ofs, tablestd,
                         offsetTableAddr + firstOffset, numPhysicalEntries);
      }
    }
    
/*    addComment(ofs, "dungeon 0");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA50A4, 0x2B);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA50FA, 40);
    
    addComment(ofs, "dungeon 1");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xa6390, 0x4c/2);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xa63dc, 36);
    
    addComment(ofs, "dungeon 2");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA7EB2, 0x3A/2);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA7EEC, 0x3A/2);
    
    addComment(ofs, "dungeon 3");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xA8A6E, 0x3A/2);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xA7EEC, 0x3A/2); */
    
    addComment(ofs, "shop");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xb063C, 0x78/2);
    dumpScriptsAtPos(ifs, ofs, tablestd, 0xb06b4, 0x78/2);
    
    addComment(ofs, "intro and ending");
    dumpScriptOffsetTable(ifs, ofs, tablestd, 0xb1090, 0xb6/2);
//    dumpScriptsAtPos(ifs, ofs, tablestd, 0xb1146, 0xb6/2);
  }
  catch (BlackT::TGenericException& e) {
    std::cerr << "Exception: " << e.problem() << std::endl;
    return 1;
  }
  
  
  return 0;
} 
