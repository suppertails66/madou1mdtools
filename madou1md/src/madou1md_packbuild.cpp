#include "md/Madou1MdCmp.h"
#include "md/PsCmp.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TOpt.h"
#include "util/TStringConversion.h"
#include "exception/TGenericException.h"
#include <vector>
#include <iostream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Md;

//int maxBlockSizeInPatterns = 0x100;
//int maxBlockSizeInBytes = 0x2000;
int maxBlockSizeInBytes = 0x10000;
int maxBlockSizeInPatterns = maxBlockSizeInBytes/0x20;

bool verbose = true;

std::string asHex(int value) {
  return string("$")
    + TStringConversion::intToString(value, TStringConversion::baseHex)
          .substr(2, string::npos);
}

std::string asHex2b(int value) {
  string result =
    TStringConversion::intToString(value, TStringConversion::baseHex)
          .substr(2, string::npos);
  while (result.size() < 2) result = string("0") + result;
  return string("$") + result;
}

void bin2dcb(TStream& ifs, std::ostream& ofs, int constsPerLine = 16) {
  while (true) {
    if (ifs.eof()) break;
    
    ofs << "  dc.b ";
    
    for (int i = 0; i < constsPerLine; i++) {
      if (ifs.eof()) break;
      
      TByte next = ifs.get();
//      ofs << as2bHexPrefix(next);
      ofs << asHex2b(next);
      if (!ifs.eof() && (i != constsPerLine - 1)) ofs << ",";
    }
    
    ofs << std::endl;
  }
}

class Madou1MdGrpBank;
class Madou1MdGrpPack;
class Madou1MdGrpPackItem;

typedef std::vector<Madou1MdGrpPack> GrpPackCollection;
typedef std::vector<Madou1MdGrpPackItem> GrpPackItemCollection;

class Madou1MdGrpPackItem {
public:
  
  Madou1MdGrpPackItem() { }
  Madou1MdGrpPackItem(std::string name__,
                      int dstAddr__)
    : name(name__),
      dstAddr(dstAddr__) { }
  
  std::string name;
  int dstAddr;
};

class Madou1MdGrpPack {
public:
  
//  std::string inprefix;
//  int numItems;

  void addItem(std::string name, int dstAddr) {
    items.push_back(Madou1MdGrpPackItem(name, dstAddr));
  }
  
  GrpPackItemCollection items;
};

class Madou1MdGrpBank {
public:
  GrpPackCollection packs;
  
/*  void addPack(std::string inprefix, int numItems) {
    Madou1MdGrpPack pack;
    pack.inprefix = inprefix;
    pack.numItems = numItems;
    packs.push_back(pack);
  } */
  
  void addPack(Madou1MdGrpPack pack) {
    packs.push_back(pack);
  }
  
  void output(std::string outprefix, int baseAddr,
                  bool addHeaderTerminator = true) {
    // - for the entire bank, output the raw data as a file
    // - for each pack, output an include file containing the pack
    //   headers as raw binary data
  
//    ofstream incOfs((outprefix + "include.inc").c_str());
    TBufStream datOfs;
    
    if (verbose) cout << "outputting " << outprefix << " to "
      << TStringConversion::intToString(baseAddr,
            TStringConversion::baseHex)
      << endl;
  
    // compute size of initial subheader pointers and skip
    int subheaderPointersBaseAddr = baseAddr;
    int numSubheaderPointers = 0;
    for (GrpPackCollection::iterator it = packs.begin();
         it != packs.end();
         ++it) {
//      numSubheaderPointers += it->items.size();
      Madou1MdGrpPack& pack = *it;
      for (GrpPackItemCollection::iterator jt = pack.items.begin();
           jt != pack.items.end();
           ++jt) {
        Madou1MdGrpPackItem& item = *jt;
        TIfstream ifs(item.name.c_str(), ios_base::binary);
        int sz = ifs.size();
        numSubheaderPointers += (ifs.size() / maxBlockSizeInBytes);
        if ((sz % maxBlockSizeInBytes) != 0) ++numSubheaderPointers;
      }
    }
    
    // compute size of headers and skip
//    int headersBaseAddr
//      = subheaderPointersBaseAddr + (numSubheaderPointers * 2);
//    int numHeaders = packs.size();
    int numSubheaders = numSubheaderPointers;
    
    // compute size of initial subheaders and skip
    int subheadersBaseAddr
      = subheaderPointersBaseAddr + (numSubheaderPointers * 2);
    
    // pack data
    // FIXME: should be (numSubheaders * 6) + (numSubheaderSections * 2)
    int dataBaseAddr
      = subheadersBaseAddr + (numSubheaders * 8);
    
    int subheaderPointersPutAddr = subheaderPointersBaseAddr;
    int subheadersPutAddr = subheadersBaseAddr;
    int dataPutAddr = dataBaseAddr;
    
    int packNum = 0;
    for (GrpPackCollection::iterator it = packs.begin();
         it != packs.end();
         ++it) {
      if (verbose) {
        cout << "pack "
          << TStringConversion::intToString(packNum,
                TStringConversion::baseHex)
          << endl;
      }
        
      TBufStream headersOfs;
      
      Madou1MdGrpPack& pack = *it;
      
      int itemNum = 0;
      for (GrpPackItemCollection::iterator jt = pack.items.begin();
           jt != pack.items.end();
           ++jt) {
        if (verbose) {
          cout << "  item "
            << TStringConversion::intToString(itemNum,
                  TStringConversion::baseHex)
            << endl;
          cout << "    subheaderPointersPutAddr: "
            << TStringConversion::intToString(subheaderPointersPutAddr,
                  TStringConversion::baseHex)
            << endl
               << "    subheadersPutAddr: "
            << TStringConversion::intToString(subheadersPutAddr,
                  TStringConversion::baseHex)
            << endl
               << "    dataPutAddr: "
            << TStringConversion::intToString(dataPutAddr,
                  TStringConversion::baseHex)
            << endl;
        }
        
        Madou1MdGrpPackItem& item = *jt;
        
        // open source file
        TBufStream ifs;
        ifs.open(item.name.c_str());
        
        int remainingSrcData = ifs.size();
        // individual transfers are limited to 0x100 patterns
        int numSubfiles = remainingSrcData / maxBlockSizeInBytes;
        if ((remainingSrcData % maxBlockSizeInBytes) != 0) ++numSubfiles;
        
        int vdpPutPos = item.dstAddr;
        for (int i = 0; i < numSubfiles; i++) {
          int sizeInPatterns = (remainingSrcData >= maxBlockSizeInBytes)
            ? maxBlockSizeInPatterns
            : (remainingSrcData / 0x20);
          int sizeInBytes = sizeInPatterns * 0x20;
          remainingSrcData -= sizeInBytes;
          
          // write subheader pointer
          int subheaderPointerAddr = subheaderPointersPutAddr;
          datOfs.seek(subheaderPointerAddr - baseAddr);
          datOfs.writeu16be(subheadersPutAddr & 0xFFFF);
          subheaderPointersPutAddr += 2;
          
          // write header
          // mode (mode 1)
          headersOfs.writeu16be(0x8000);
          // packed source subheader pointer
          headersOfs.writeu16be(((subheaderPointerAddr & 0xFF8000) >> 8)
            | (subheaderPointerAddr & 0x7F));
          // vdp putpos
          headersOfs.writeu16be(vdpPutPos);
          
          // write subheader
          datOfs.seek(subheadersPutAddr - baseAddr);
          // cmpSettings (mode 1/locked)
          datOfs.writeu8(0xC0);
          // blockSize
//          datOfs.writeu8((sizeInPatterns == 0x100) ? 0 : sizeInPatterns);
          datOfs.writeu8(0);
          // current vdp offset
          datOfs.writeu16be(0x0000);
          // packed source data addr
          datOfs.writeu16be(dataPutAddr & 0xFFFF);
          subheadersPutAddr += 6;
          
          // write compressed data
          datOfs.seek(dataPutAddr - baseAddr);
          int dataStart = datOfs.tell();
/*          int remainingBytes = sizeInBytes;
          while (remainingBytes > 0) {
            int len = (remainingBytes < 0x7F) ? remainingBytes : 0x7F;
            // absolute run
            datOfs.writeu8(len);
//            for (int i = 0; i < len; i++) datOfs.put(ifs.get());
            datOfs.writeFrom(ifs, len);
            remainingBytes -= len;
          } */
//          TBufStream compressedOfs;
//          PsCmp::cmpPs(ifs, compressedOfs, 1);
//          compressedOfs.seek(0);
//          datOfs.writeFrom(compressedOfs, compressedOfs.size());
          int remainingBytes = sizeInBytes;
          while (remainingBytes > 0) {
            // make some token effort at reducing the size.
            // i implemented this solely because one of the graphics i needed
            // to include took up almost the entirety of vram and wouldn't
            // fit in a graphics bank otherwise.
            // it's hideously wasteful in every regard but does what it
            // needs to.
            int ifsPos = ifs.tell();
            int repeatLen = 0;
            char initial = ifs.get();
            while (!ifs.eof() && (repeatLen < 0x80)) {
              if (ifs.peek() == initial) {
                ++repeatLen;
                ifs.get();
              }
              else {
                break;
              }
            }
            
            if (repeatLen >= 5) {
              // put initial byte as an absolute
              datOfs.writeu8(0x01);
              datOfs.writeu8(initial);
              
              // put rest as a 1-byte lookback
              datOfs.writeu8((repeatLen - 3) | 0x80);
              datOfs.writeu8(0x00);
              
              remainingBytes -= (repeatLen + 1);
            }
            else {
              // shove in a giant absolute block
              ifs.seek(ifsPos);
              
              int len = (remainingBytes < 0x7F) ? remainingBytes : 0x7F;
              // absolute run
              datOfs.writeu8(len);
  //            for (int i = 0; i < len; i++) datOfs.put(ifs.get());
              datOfs.writeFrom(ifs, len);
              remainingBytes -= len;
            }
          }
          dataPutAddr += (datOfs.tell() - dataStart);
          
          // write data terminator
          datOfs.put(0x00);
          ++dataPutAddr;
          
          // done
          vdpPutPos += sizeInBytes;
        }
        
        // write subheader terminator
        datOfs.seek(subheadersPutAddr - baseAddr);
        datOfs.writeu16be(0xFFFF);
        subheadersPutAddr += 2;
        
        ++itemNum;
      }
      
      // write header terminator
      if (addHeaderTerminator) headersOfs.writeu16be(0xFFFF);
      
      // convert headersOfs to include constants and output result
      {
        string numStr = TStringConversion::intToString(packNum);
        std::ofstream ofs((outprefix + "-" + numStr + ".inc").c_str(),
                          std::ios_base::trunc);
        headersOfs.seek(0);
        bin2dcb(headersOfs, ofs);
      }
      
      ++packNum;
    }
    
    if (datOfs.size() > 0x10000) {
      throw TGenericException(T_SRCANDLINE,
                              "Madou1MdGrpBank::output()",
                              string("Pack too large for 0x10000-byte")
                                + " bank: "
                                + outprefix
                                + " (size: "
                                + TStringConversion::intToString(datOfs.size(),
                                    TStringConversion::baseHex)
                                + ")");
    }
    
    // save bank data
    datOfs.save((outprefix + ".bin").c_str());
  }
};

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Madou Monogatari I hardcoded graphics pack builder" << endl;
    cout << "Usage: "
         << argv[0] << " <inprefix> <outprefix>" << endl;
    
    return 0;
  }
  
  try {
  
    string inprefix = string(argv[1]);
    string outprefix = string(argv[2]);
    
/*    Madou1MdGrpPack test1;
    test1.addItem(inprefix + "title-0-0x0.bin"   , 0x0000);
    test1.addItem(inprefix + "title-1-0x2000.bin", 0x2000);
    test1.addItem(inprefix + "title-2-0x4000.bin", 0x4000);
    test1.addItem(inprefix + "title-3-0x8000.bin", 0x8000);
    test1.addItem(inprefix + "title-4-0xC000.bin", 0xC000);
    test1.addItem(inprefix + "title-5-0xE000.bin", 0xE000);
    
    Madou1MdGrpPack test2;
    test2.addItem(inprefix + "title-0-0x0.bin"   , 0x0000);
    test2.addItem(inprefix + "title-1-0x2000.bin", 0x2000);
    test2.addItem(inprefix + "title-2-0x4000.bin", 0x4000);
    test2.addItem(inprefix + "title-3-0x8000.bin", 0x8000);
    test2.addItem(inprefix + "title-4-0xC000.bin", 0xC000);
    test2.addItem(inprefix + "title-5-0xE000.bin", 0xE000);
    
    Madou1MdGrpBank testBank;
    testBank.addPack(test1);
    testBank.addPack(test2); */
    
    Madou1MdGrpPack titleLogo;
//    titleLogo.addItem(inprefix + "rsrc_raw/decmp/title-0-0x0.bin", 0x0000);
    titleLogo.addItem(inprefix + "out/grp/title_logo.bin", 0x0000);
    Madou1MdGrpPack titleSpritetxt;
    titleSpritetxt.addItem(inprefix + "out/spritetxt/title-tiles.bin", 0x4000);
    Madou1MdGrpPack titleMainMap;
    titleMainMap.addItem(inprefix + "out/maps/title_main.bin", 0xC000);
    Madou1MdGrpPack titleSubMap;
    titleSubMap.addItem(inprefix + "out/maps/title_sub.bin", 0xE000);
    Madou1MdGrpPack examscoreBgGrp;
    examscoreBgGrp.addItem(inprefix + "out/grp/examscore_bg.bin", 0x2000);
    Madou1MdGrpPack examscoreBgMap;
    examscoreBgMap.addItem(inprefix + "out/maps/examscore_bg.bin", 0xE000);
    Madou1MdGrpPack examscoreSprites;
    examscoreSprites.addItem(inprefix + "out/grp/examscore-1-0x4000.bin", 0x4000);
    
    Madou1MdGrpBank bank240000;
    bank240000.addPack(titleLogo);
    bank240000.addPack(titleSpritetxt);
    bank240000.addPack(titleMainMap);
    bank240000.addPack(titleSubMap);
    bank240000.addPack(examscoreBgGrp);
    bank240000.addPack(examscoreBgMap);
    bank240000.addPack(examscoreSprites);
    bank240000.output(outprefix + "pack240000", 0x240000, false);
    
    Madou1MdGrpPack introPokanMap;
    introPokanMap.addItem(inprefix + "out/maps/intro_pokan.bin", 0xE000);
    Madou1MdGrpPack introPokanGrp;
    introPokanGrp.addItem(inprefix + "out/grp/intro_pokan.bin", 0x2000);
    Madou1MdGrpPack introDoki;
    introDoki.addItem(inprefix + "out/grp/intro_doki-1-0x4000.bin", 0x4000);
    Madou1MdGrpPack introFinal;
    introFinal.addItem(inprefix + "out/grp/intro_final-2-0x4000.bin", 0x4000);
    Madou1MdGrpPack bayoenNameGrp;
    bayoenNameGrp.addItem(inprefix + "out/grp/bayoen_name.bin", 0xA000);
    Madou1MdGrpPack panottyMainGrp;
    panottyMainGrp.addItem(inprefix + "out/grp/panotty_main-0-0x9000.bin", 0x9000);
    Madou1MdGrpPack panottyWahGrp;
    panottyWahGrp.addItem(inprefix + "out/grp/panotty_wah-0-0x9000.bin", 0x9000);
    Madou1MdGrpPack compileSloganGrp;
    compileSloganGrp.addItem(inprefix + "out/grp/compile_logo-1-0x2000.bin", 0x2000);
    Madou1MdGrpPack battleMainGrp;
    battleMainGrp.addItem(inprefix + "out/grp/battle_main-2-0x680.bin", 0x680);
    Madou1MdGrpPack mrFleaGrp;
    mrFleaGrp.addItem(inprefix + "out/grp/mrflea-0-0x5600.bin", 0x5600);
    Madou1MdGrpPack panottyAmigoMainGrp;
    panottyAmigoMainGrp.addItem(inprefix + "out/grp/panotty_amigo_main-0-0x3C00.bin", 0x3C00);
    Madou1MdGrpPack panottyAmigoWahGrp;
    panottyAmigoWahGrp.addItem(inprefix + "out/grp/panotty_amigo_wah-0-0x3C00.bin", 0x3C00);
    Madou1MdGrpPack mrFleaAmigoWahGrp;
    mrFleaAmigoWahGrp.addItem(inprefix + "out/grp/mrflea_amigo-0-0x1C00.bin", 0x1C00);
    Madou1MdGrpPack timerGrp;
    timerGrp.addItem(inprefix + "out/grp/timer-0-0x5600.bin", 0x5600);
    Madou1MdGrpPack cockadoodleGrp;
    cockadoodleGrp.addItem(inprefix + "out/grp/cockadoodle.bin", 0xB000);
    Madou1MdGrpPack demonEscapeGrp;
    demonEscapeGrp.addItem(inprefix + "out/grp/demon_escape-0-0x5600.bin", 0x5600);
    Madou1MdGrpPack escapeDoorsGrp;
    escapeDoorsGrp.addItem(inprefix + "out/grp/escape_doors-0-0x5C80.bin", 0x5C80);
    
    Madou1MdGrpBank bank250000;
    bank250000.addPack(introPokanMap);
    bank250000.addPack(introPokanGrp);
    bank250000.addPack(introDoki);
    bank250000.addPack(introFinal);
    bank250000.addPack(bayoenNameGrp);
    bank250000.addPack(panottyMainGrp);
    bank250000.addPack(panottyWahGrp);
    bank250000.addPack(compileSloganGrp);
    bank250000.addPack(battleMainGrp);
    bank250000.addPack(mrFleaGrp);
    bank250000.addPack(panottyAmigoMainGrp);
    bank250000.addPack(panottyAmigoWahGrp);
    bank250000.addPack(mrFleaAmigoWahGrp);
    bank250000.addPack(timerGrp);
    bank250000.addPack(cockadoodleGrp);
    bank250000.addPack(demonEscapeGrp);
    bank250000.addPack(escapeDoorsGrp);
    bank250000.output(outprefix + "pack250000", 0x250000, false);
    
    Madou1MdGrpPack karaokeGrp;
    karaokeGrp.addItem(inprefix + "out/grp/karaoke-0-0x0.bin", 0x0);
    Madou1MdGrpPack skeletonTGrp;
    skeletonTGrp.addItem(inprefix + "out/grp/skeletont-0-0x5600.bin", 0x5600);
    Madou1MdGrpPack skeletonTDefeatedGrp;
    skeletonTDefeatedGrp.addItem(
      inprefix + "out/grp/skeletont-1-0x9000.bin", 0x9000);
    
    Madou1MdGrpBank bank260000;
    bank260000.addPack(karaokeGrp);
    bank260000.addPack(skeletonTGrp);
    bank260000.addPack(skeletonTDefeatedGrp);
    bank260000.output(outprefix + "pack260000", 0x260000, false);
    
    
    Madou1MdGrpPack badEndGrp;
    badEndGrp.addItem(inprefix + "out/grp/badend-1-0x4000.bin", 0x4000);
    
    Madou1MdGrpBank bank270000;
    bank270000.addPack(badEndGrp);
    for (int i = 0; i < 10; i++) {
      Madou1MdGrpPack creditsGrp;
      creditsGrp.addItem(inprefix + "out/grp/credits_"
        + TStringConversion::intToString(i)
        + ".bin", 0xF000);
      bank270000.addPack(creditsGrp);
    }
    Madou1MdGrpPack creditsGrp10;
    creditsGrp10.addItem(inprefix + "out/grp/credits_10.bin", 0x0200);
    bank270000.addPack(creditsGrp10);
    for (int i = 0; i < 10; i++) {
      Madou1MdGrpPack creditsTopGrp;
      creditsTopGrp.addItem(inprefix + "out/grp/credits"
        + TStringConversion::intToString(i)
        + "-0-0x0"
        + ".bin", 0x0000);
      bank270000.addPack(creditsTopGrp);
    }
    bank270000.output(outprefix + "pack270000", 0x270000, false);
  }
  catch (TGenericException& e) {
    cerr << "Error: " << e.problem() << endl;
    return 1;
  }
  catch (TException& e) {
    cerr << "Error: " << e.what() << endl;
    return 1;
  }
  catch (std::exception& e) {
    cerr << "Error: " << e.what() << endl;
    return 1;
  }
  
  return 0;
} 
