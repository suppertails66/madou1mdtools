#ifndef MADOU1MDCMP_H
#define MADOU1MDCMP_H


#include "util/TStream.h"

namespace Md {


namespace Madou1MdCmpModes {
  enum Madou1MdCmpMode {
    mode0,
    mode1
  };
}

namespace Madou1MdCmpSubmodes {
  enum Madou1MdCmpSubmode {
    submode0,
    submode1
  };
}

namespace Madou1MdBlockModes {
  enum Madou1MdBlockMode {
    unlocked,
    locked
  };
}

/*class Madou1MdCmp {
public:
  
  struct Madou1MdCmpSubheader{
    Madou1MdCmpSubmodes::Madou1MdCmpSubmode submode;
    Madou1MdBlockModes::Madou1MdBlockMode blockMode;
    int userBlockSizeInPatterns;
    int dstOffset;
    int srcAddr;
  };
  
  static void decmpFromHeader(BlackT::TStream& rom, int headerOffset,
                              BlackT::TStream& dst,
                              bool expandedDefaultBlockSizes = false,
                              bool verbose = false);
  
  static void decmp(BlackT::TStream& rom, int initialSubheaderOffset,
                    BlackT::TStream& dst,
                    bool expandedDefaultBlockSizes = false,
                    bool verbose = false);
  
protected:

  bool verbose;
  
  // note: initial subheader address needed to unpack srcAddress
  static Madou1MdCmpSubheaderreadSubheader(BlackT::TStream& rom, int initialSubheaderAddr,
                                 bool verbose = false);
  
}; */
  
struct Madou1MdCmpSubheader {
  Madou1MdCmpSubmodes::Madou1MdCmpSubmode submode;
  Madou1MdBlockModes::Madou1MdBlockMode blockMode;
  int userBlockSizeInPatterns;
  int dstOffset;
  int srcAddr;
};

class Madou1MdPackDecompressor {
public:
  
  Madou1MdPackDecompressor(
                         BlackT::TStream& rom_, int headerOffset_,
                         BlackT::TStream& dst_,
                         bool expandedDefaultBlockSizes_ = false,
                         bool verbose_ = false);
  
  void operator()();
  
protected:

  BlackT::TStream& rom;
  int headerOffset;
  BlackT::TStream& dst;
  bool expandedDefaultBlockSizes;
  bool verbose;
  
};

class Madou1MdDecompressor {
public:
  
  Madou1MdDecompressor(
                         BlackT::TStream& rom_, int headerOffset_,
                         BlackT::TStream& dst_,
                         Madou1MdCmpModes::Madou1MdCmpMode cmpMode_,
                         bool expandedDefaultBlockSizes_ = false,
                         bool verbose_ = false);
  
  void operator()();
  
protected:

  BlackT::TStream& rom;
  int headerOffset;
  BlackT::TStream& dst;
  bool expandedDefaultBlockSizes;
  bool verbose;
  Madou1MdCmpModes::Madou1MdCmpMode cmpMode;
  Madou1MdCmpSubheader subheader;
  int remainingBlockBytes;
  int pendingCompressionCommand;
  int currentCommandLen;
  int currentLookbackLen;
  bool done;
  
  void decmp(int initialSubheaderOffset);
  
  // note: initial subheader address needed to unpack srcAddress
  Madou1MdCmpSubheader readSubheader(int initialSubheaderAddr);
  
  static int getDefaultBlockSize(
    Madou1MdCmpModes::Madou1MdCmpMode mode,
    Madou1MdCmpSubmodes::Madou1MdCmpSubmode submode,
    bool expandedSizes);
  
};


}


#endif
