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

const static int op_space   = 0x00;
//const static int op_clear   = 0xFD;
const static int op_wait    = 0xC4;
const static int op_br      = 0xC3;
const static int op_end     = 0xFF;

// added for translation
const static int op_tilebr  = 0x1F;

void patchScriptsToRom(TStream& ifs, TStream& rom, int outputDataStartOffset) {
  Madou1MdScriptReader::ResultCollection results;
  Madou1MdScriptReader(ifs, results, table)();
  
  int numScriptTableEntries = results.size();
  int newScriptPointerTableBase = outputDataStartOffset;
  int currentScriptOffset = outputDataStartOffset + (numScriptTableEntries * 4);
  
  int scriptNum = -1;
  for (Madou1MdScriptReader::ResultCollection::iterator it = results.begin();
       it != results.end();
       ++it) {
    ++scriptNum;
    Madou1MdScriptReader::ResultString script = *it;
    int origScriptOffset = script.srcOffset;
    
    // if output size < 4, assume this is contentless and we can't fit in
    // a jump command
    if (script.str.size() < 4) continue;
    
    // write pointer to this script's data
    rom.seek(newScriptPointerTableBase + (scriptNum * 4));
    rom.writeu32be(currentScriptOffset);
    
    // create jump command to new script
    rom.seek(origScriptOffset);
    rom.writeu16be(0xFFF8);
    rom.writeu16be(scriptNum);
    
    // write new script
    rom.seek(currentScriptOffset);
    rom.write(script.str.c_str(), script.str.size());
    currentScriptOffset += script.str.size();
    
    // ensure scripts have word alignment
    if ((currentScriptOffset & 1) != 0) ++currentScriptOffset;
  }
}

void exportRawResults(Madou1MdScriptReader::ResultCollection& results,
                      std::string filename) {
  TBufStream ofs;
  for (int i = 0; i < results.size(); i++) {
    ofs.write(results[i].str.c_str(), results[i].str.size());
  }
  ofs.save((filename).c_str());
}

void exportRawResults(TStream& ifs,
                      std::string filename) {
  Madou1MdScriptReader::ResultCollection results;
  Madou1MdScriptReader(ifs, results, table)();
  exportRawResults(results, filename);
}

void exportTabledResults(TStream& ifs,
                         std::string binFilename,
                         Madou1MdScriptReader::ResultCollection& results,
                         TBufStream& ofs) {
  int offset = 0;
  for (int i = 0; i < results.size(); i++) {
    ofs.writeu16be(offset + (results.size() * 2));
    offset += results[i].str.size();
  }
  
  for (int i = 0; i < results.size(); i++) {
    ofs.write(results[i].str.c_str(), results[i].str.size());
  }
  
  ofs.save((binFilename).c_str());
}

void exportTabledResults(TStream& ifs,
                         std::string binFilename) {
  Madou1MdScriptReader::ResultCollection results;
  Madou1MdScriptReader(ifs, results, table)();
  
//  std::ofstream incofs(incFilename.c_str());
  TBufStream ofs;
  exportTabledResults(ifs, binFilename, results, ofs);
}

/*string getStringName(Madou1MdScriptReader::ResultString result) {
//  int bankNum = result.srcOffset / 0x4000;
  return string("string_")
    + TStringConversion::intToString(result.srcOffset,
          TStringConversion::baseHex);
}

void exportSizeTabledResults(TStream& ifs,
                         std::string binFilename) {
  Madou1MdScriptReader::ResultCollection results;
  Madou1MdScriptReader(ifs, results, table)();
  
//  std::ofstream incofs(incFilename.c_str());
  TBufStream ofs(0x10000);
  ofs.writeu8(results.size());
  exportTabledResults(ifs, binFilename, results, ofs);
}

void generateHashTable(string infile, string outPrefix, string outName) {
  TBufStream ifs;
//    ifs.open((inPrefix + "script.txt").c_str());
//  ifs.open((outPrefix + "script_wrapped.txt").c_str());
  ifs.open(infile.c_str());
  
  Madou1MdScriptReader::ResultCollection results;
  Madou1MdScriptReader(ifs, results, table)();
  
//    TBufStream ofs(0x20000);
//    for (unsigned int i = 0; i < results.size(); i++) {
//      ofs.write(results[i].str.c_str(), results[i].str.size());
//    }
//    ofs.save((outPrefix + "script.bin").c_str());
  
  // create:
  // * an individual .bin file for each compiled string
  // * a .inc containing, for each string, one superfree section with an
  //   incbin that includes the corresponding string's .bin
  // * a .inc containing the hash bucket arrays for the remapped strings.
  //   table keys are (orig_pointer & 0x1FFF).
  //   the generated bucket sets go in a single superfree section.
  //   each bucket set is an array of the following structure (terminate
  //   arrays with FF so we can detect missed entries):
  //       struct Bucket {
  //       u8 origBank
  //       u16 origPointer  // respects original slotting!
  //       u8 newBank
  //       u16 newPointer
  //     }
  // * a .inc containing the bucket array start pointers (keys are 16-bit
  //   and range from 0x0000-0x1FFF, so this gets its own bank)
  
  std::ofstream strIncOfs(
    (outPrefix + "strings" + outName + ".inc").c_str());
  std::map<int, Madou1MdScriptReader::ResultCollection>
    mappedStringBuckets;
  for (unsigned int i = 0; i < results.size(); i++) {
    std::string stringName = getStringName(results[i]) + outName;
    
    // write string to file
    TBufStream ofs(0x10000);
    ofs.write(results[i].str.c_str(), results[i].str.size());
    ofs.save((outPrefix + "strings/" + stringName + ".bin").c_str());
    
    // add string binary to generated includes
    strIncOfs << ".slot 2" << endl;
    strIncOfs << ".section \"string include " << outName << " "
      << i << "\" superfree"
      << endl;
    strIncOfs << "  " << stringName << ":" << endl;
    strIncOfs << "    " << ".incbin \""
      << outPrefix << "strings/" << stringName << ".bin"
      << "\"" << endl;
    strIncOfs << ".ends" << endl;
    
    // add to map
    mappedStringBuckets[results[i].srcOffset & hashMask]
      .push_back(results[i]);
  }
  
  // generate bucket arrays
  std::ofstream stringHashOfs(
    (outPrefix + "string_bucketarrays" + outName + ".inc").c_str());
  stringHashOfs << ".include \""
    << outPrefix + "strings" + outName + ".inc\""
    << endl;
  stringHashOfs << ".section \"string hash buckets " << outName
    << "\" superfree" << endl;
  stringHashOfs << "  stringHashBuckets" + outName + ":" << endl;
  for (std::map<int, Madou1MdScriptReader::ResultCollection>::iterator it
         = mappedStringBuckets.begin();
       it != mappedStringBuckets.end();
       ++it) {
    int key = it->first;
    Madou1MdScriptReader::ResultCollection& results = it->second;
    
    stringHashOfs << "  hashBucketArray_"
      << outName
      << TStringConversion::intToString(key,
            TStringConversion::baseHex)
      << ":" << endl;
    
    for (unsigned int i = 0; i < results.size(); i++) {
      Madou1MdScriptReader::ResultString result = results[i];
      string stringName = getStringName(result) + outName;
      
      // original bank
      stringHashOfs << "    .db " << result.srcOffset / 0x4000 << endl;
      // original pointer (respecting slotting)
      stringHashOfs << "    .dw "
        << (result.srcOffset & 0x3FFF) + (0x4000 * result.srcSlot)
        << endl;
      // new bank
      stringHashOfs << "    .db :" << stringName << endl;
      // new pointer
      stringHashOfs << "    .dw " << stringName << endl;
    }
    
    // array terminator
    stringHashOfs << "  .db $FF " << endl;
  }
  stringHashOfs << ".ends" << endl;
  
  // generate bucket array hash table
  std::ofstream bucketHashOfs(
    (outPrefix + "string_bucket_hashtable" + outName + ".inc").c_str());
  bucketHashOfs << ".include \""
    << outPrefix + "string_bucketarrays" + outName + ".inc\""
    << endl;
  bucketHashOfs
    << ".section \"bucket array hash table " << outName
      << "\" size $4000 align $4000 superfree"
    << endl;
  bucketHashOfs << "  bucketArrayHashTable" << outName << ":" << endl;
  for (int i = 0; i < hashMask; i++) {
    std::map<int, Madou1MdScriptReader::ResultCollection>::iterator findIt
      = mappedStringBuckets.find(i);
    if (findIt != mappedStringBuckets.end()) {
      int key = findIt->first;
      // bucket bank
      bucketHashOfs << "    .db :hashBucketArray_" + outName
        << TStringConversion::intToString(key,
              TStringConversion::baseHex)
        << endl;
      // bucket pointer
      bucketHashOfs << "    .dw hashBucketArray_" + outName
        << TStringConversion::intToString(key,
              TStringConversion::baseHex)
        << endl;
      // reserved
      bucketHashOfs << "    .db $FF"
        << endl;
    }
    else {
      // no array
      bucketHashOfs << "    .db $FF,$FF,$FF,$FF" << endl;
    }
  }
  bucketHashOfs << ".ends" << endl;
} */

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Madou Monogatari I (Mega Drive) script builder" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [thingy] [rom] [outprefix]"
      << endl;
    
    return 0;
  }
  
  string inPrefix = string(argv[1]);
  string tableName = string(argv[2]);
  string romName = string(argv[3]);
  string outPrefix = string(argv[4]);
  
  table.readSjis(tableName);
  
  TBufStream rom;
  rom.open(romName.c_str());
  
  // TODO
  // wrap script
  {
    int numChars = 0;
    
    // read size table
    Madou1MdLineWrapper::CharSizeTable sizeTable;
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
    Madou1MdLineWrapper::KerningMatrix kerningMatrix(numChars, numChars);
    {
      TBufStream ifs;
      ifs.open("out/font/kerning.bin");
      
      for (int j = 0; j < numChars; j++) {
        for (int i = 0; i < numChars; i++) {
          kerningMatrix.data(i, j) = ifs.reads8();
        }
      }
    }
    
    {
      TBufStream ifs;
      ifs.open((inPrefix + "script.txt").c_str());
      
      TLineWrapper::ResultCollection results;
      Madou1MdLineWrapper(ifs, results, table, sizeTable, kerningMatrix)();
      
      if (results.size() > 0) {
        TOfstream ofs((outPrefix + "script_wrapped.txt").c_str());
        ofs.write(results[0].str.c_str(), results[0].str.size());
      }
    }
  }

  {
    TBufStream ifs;
    ifs.open((outPrefix + "script_wrapped.txt").c_str());
//    ifs.open((inPrefix + "script.txt").c_str());
    
//    exportTabledResults(ifs, outPrefix + "region0.bin");
    patchScriptsToRom(ifs, rom, 0x210000);
  }

  {
    TBufStream ifs;
    ifs.open((inPrefix + "new.txt").c_str());
    
//    patchScriptsToRom(ifs, rom, 0x210000);
    
    exportRawResults(ifs, outPrefix + "capsule_plural_release_prompt.bin");
    exportRawResults(ifs, outPrefix + "capsule_plural_released.bin");
    exportRawResults(ifs, outPrefix + "monster_encounter_plural.bin");
    exportRawResults(ifs, outPrefix + "hungry_elephant_short.bin");
    exportRawResults(ifs, outPrefix + "monster_defeated_plural.bin");
    exportRawResults(ifs, outPrefix + "momomo_fireext_deposit.bin");
    exportRawResults(ifs, outPrefix + "momomo_fireext_withdraw.bin");
  }

  {
    TBufStream ifs;
    ifs.open((inPrefix + "item_articles_indefinite.txt").c_str());
    exportTabledResults(ifs, outPrefix + "item_articles_indefinite.bin");
  }

  {
    TBufStream ifs;
    ifs.open((inPrefix + "item_demonstratives.txt").c_str());
    exportTabledResults(ifs, outPrefix + "item_demonstratives.bin");
  }
  
  rom.save(romName.c_str());
  
  // tilemaps/new
/*  {
    TBufStream ifs;
    ifs.open((inPrefix + "tilemaps.txt").c_str());
    
    exportRawResults(ifs, outPrefix + "roulette_right.bin");
    exportRawResults(ifs, outPrefix + "roulette_wrong.bin");
    exportRawResults(ifs, outPrefix + "roulette_timeup.bin");
    exportRawResults(ifs, outPrefix + "roulette_perfect.bin");
    exportRawResults(ifs, outPrefix + "roulette_blank.bin");
    
    exportRawResults(ifs, outPrefix + "mainmenu_help.bin");
    
    exportSizeTabledResults(ifs, outPrefix + "credits.bin");
  } */
  
  return 0;
}

