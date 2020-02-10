#include "md/Madou1MdCmp.h"
#include "util/TByte.h"
#include "util/TStringConversion.h"
#include <iostream>

using namespace BlackT;

namespace Md {

  Madou1MdPackDecompressor::Madou1MdPackDecompressor(
                         BlackT::TStream& rom_, int headerOffset_,
                         BlackT::TStream& dst_,
                         bool expandedDefaultBlockSizes_,
                         bool verbose_)
    : rom(rom_),
      headerOffset(headerOffset_),
      dst(dst_),
      expandedDefaultBlockSizes(expandedDefaultBlockSizes_),
      verbose(verbose_) { }

  void Madou1MdPackDecompressor::operator()() {
    if (verbose) {
      std::cout << "*** Reading header at "
        << TStringConversion::intToString(headerOffset,
                                          TStringConversion::baseHex)
        << std::endl;
    }
    
    rom.seek(headerOffset);
    
    /* 
      header format:
        1b command
           * if 0xFF, end of pack.
           * if 0xFE, skip this entry.
           * if bit 7 not set, use compression mode 0.
             mode 0 decompresses to RAM rather than VRAM
             and does not support uncompressed blocks.
           * if bit 7 set, use compression mode 1 (lookback+uncompressed)
        1b word padding
        2b source data address packed to a word.
           decode as:
             srcaddr = ((word << 8) & 0xFF8000) | (lowbyte & 0x7F)
           e.g. 0x0D22 becomes 0xD0022.
        2b dstaddr
           for mode 0, this targets RAM  0xFFXXXX.
           for mode 1, this targets VRAM 0xXXXX.
     */
    
    TByte headerCmd = rom.readu8();
    TByte headerLow = rom.readu8();
    int srcAddrPacked = rom.readu16be();
    int dstAddr = rom.readu16be();
    
    if (headerCmd == 0xFF) return;
    if (headerCmd == 0xFE) return;
    
    Madou1MdCmpModes::Madou1MdCmpMode cmpMode;
    if ((headerCmd & 0x80) != 0) cmpMode = Madou1MdCmpModes::mode1;
    else cmpMode = Madou1MdCmpModes::mode0;
    
    int baseAddr = ((srcAddrPacked << 8) & 0xFF8000);
    
    int srcAddr = baseAddr | (srcAddrPacked & 0x7F);
    
    if (verbose) {
      std::cout
        << "  headerCmd: "
        << TStringConversion::intToString(headerCmd,
                                          TStringConversion::baseHex)
        << std::endl
        << "  headerLow: "
        << TStringConversion::intToString(headerLow,
                                          TStringConversion::baseHex)
        << std::endl
        << "  srcAddrPacked: "
        << TStringConversion::intToString(srcAddrPacked,
                                          TStringConversion::baseHex)
        << std::endl
        << "  dstAddr: "
        << TStringConversion::intToString(dstAddr,
                                          TStringConversion::baseHex)
        << std::endl
        << "  cmpMode: "
        << TStringConversion::intToString(cmpMode,
                                          TStringConversion::baseHex)
        << std::endl
//        << "  blockMode: "
//        << TStringConversion::intToString(blockMode,
//                                          TStringConversion::baseHex)
//        << std::endl
        << "  srcAddr: "
        << TStringConversion::intToString(srcAddr,
                                          TStringConversion::baseHex)
        << std::endl;
    }
    
    rom.seek(srcAddr);
    int codedOffset = rom.readu16be();
    
    int initialSubheaderOffset = baseAddr | codedOffset;
    
//    decmp(initialSubheaderOffset);
    Madou1MdDecompressor(rom, initialSubheaderOffset, dst,
                         cmpMode, expandedDefaultBlockSizes, verbose)();
  }
  
  Madou1MdDecompressor::Madou1MdDecompressor(
                         BlackT::TStream& rom_, int headerOffset_,
                         BlackT::TStream& dst_,
                         Madou1MdCmpModes::Madou1MdCmpMode cmpMode_,
                         bool expandedDefaultBlockSizes_,
                         bool verbose_)
    : rom(rom_),
      headerOffset(headerOffset_),
      dst(dst_),
      cmpMode(cmpMode_),
      expandedDefaultBlockSizes(expandedDefaultBlockSizes_),
      verbose(verbose_),
      pendingCompressionCommand(-1),
      done(false) { }

  void Madou1MdDecompressor::operator()() {
//    rom.seek(headerOffset);
    decmp(headerOffset);
  }
  
  void Madou1MdDecompressor::decmp(int initialSubheaderOffset) {
    
    rom.seek(initialSubheaderOffset);
//    Madou1MdCmpSubheader subheader;
    subheader = readSubheader(initialSubheaderOffset);
    
    int subheaderPos = 6;
    
    // seek to data source offset
    rom.seek(subheader.srcAddr);
    
    while (true) {
    
      // determine block size
      int blockSize = -1;
      // if in locked compression mode, always use default block size
      if (subheader.blockMode == Madou1MdBlockModes::locked) {
        blockSize = getDefaultBlockSize(
          cmpMode, subheader.submode, expandedDefaultBlockSizes);
      }
      else {
        // get default size for curent settings
        int blockSize = getDefaultBlockSize(
          cmpMode, subheader.submode, expandedDefaultBlockSizes);
        
        if (subheader.userBlockSizeInPatterns > blockSize)
          blockSize = subheader.userBlockSizeInPatterns;
      }
      
      remainingBlockBytes = (blockSize * 32);
      
      if ((cmpMode == Madou1MdCmpModes::mode1)
          && (subheader.submode == Madou1MdCmpSubmodes::submode0)) {
        // uncompressed
        for (int i = 0; i < remainingBlockBytes; i++) {
          dst.put(rom.get());
        }
      }
      else {
        while (remainingBlockBytes > 0) {
          // get next compression command if one is not already active
          if (pendingCompressionCommand == -1) {
            pendingCompressionCommand = rom.readu8();
            
/*            if (verbose) {
              std::cout 
                << "  rom.tell() - 1: "
                << TStringConversion::intToString(rom.tell() - 1,
                                                  TStringConversion::baseHex)
                << std::endl
                << "  pendingCompressionCommand: "
                << TStringConversion::intToString(pendingCompressionCommand,
                                                  TStringConversion::baseHex)
                << std::endl
                << "  remainingBlockBytes: "
                << TStringConversion::intToString(remainingBlockBytes,
                                                  TStringConversion::baseHex)
                << std::endl;
//              char c;
//              std::cin >> c;
            } */
            
            // zero = done
            if (pendingCompressionCommand == 0) {
              remainingBlockBytes = 0;
              done = true;
              break;
            }
            // high bit set = lookback
            else if ((pendingCompressionCommand & 0x80) != 0) {
              currentCommandLen = (pendingCompressionCommand & 0x7F) + 3;
              currentLookbackLen = -(rom.readu8()) - 1;
            }
            // high bit not set = absolute
            else {
              currentCommandLen = pendingCompressionCommand;
            }
          }
          
          // execute current command
          
          // high bit set = lookback
          if ((pendingCompressionCommand & 0x80) != 0) {
            while ((remainingBlockBytes > 0) && (currentCommandLen > 0)) {
              dst.seekoff(currentLookbackLen);
              TByte next = dst.readu8();
              dst.seek(dst.size());
              dst.put(next);
              
              --remainingBlockBytes;
              --currentCommandLen;
            }
          }
          // high bit not set = absolute
          else {
            while ((remainingBlockBytes > 0) && (currentCommandLen > 0)) {
              dst.put(rom.get());
              
              --remainingBlockBytes;
              --currentCommandLen;
            }
          }
          
          // if done, mark command as complete
          if (currentCommandLen == 0) pendingCompressionCommand = -1;
        }
      }
      
      if (done == true) break;
      
      // get next subheader if not in locked mode
      if (subheader.blockMode != Madou1MdBlockModes::locked) {
        // FIXME: is this correct?? or do we read from the data stream??
        int offset = rom.tell();
        rom.seek(initialSubheaderOffset + subheaderPos);
        subheaderPos += 6;
        
        // terminator check
        if ((TByte)rom.peek() == 0xFF) break;
        
        // read next subheader
        subheader = readSubheader(initialSubheaderOffset);
        
        // seek to data source offset
        rom.seek(subheader.srcAddr);
      }
    }
    
    if (verbose) {
      std::cout << "Finished at "
                << TStringConversion::intToString(rom.tell(),
                                                  TStringConversion::baseHex)
                << std::endl;
    }
  }
  
  /*
    1b cmpSettings
        * if 0xFF, end of entry?
        * bit 7 = compression submode (only applies in compression mode 1?
                  set = lookback mode?
                  unset = uncompressed mode?
        * bit 6 = compression mode lock.
          if set, the specified compression mode applies to all future blocks,
          and there are no more headers?
    1b userBlockSizeInPatterns
        * if 0, treat as 0x100
       every time this many decompressed patterns have been written,
       read a new header (in this same format) from cmpSrcPtr.
       BUT: if compression mode is locked, this does nothing and no new header
            will ever be read.
       BUT: there are default values for this depending on compression mode,
            and if the user-specified value is lower than them, this is
            ignored and the default used instead.
            default values:
              * mode 0:
                - if bit 6 of FF8A51 unset, infinity?
                  or always user size?
                - otherwise, 0x10
              * mode 1 submode 0 (uncompressed):
                - if FF9630 zero AND bit 6 of FF8A51 unset, 0x40
                - otherwise, 0x20
              * mode 1 submode 1 (lookback):
                - if FF9630 zero AND bit 6 of FF8A51 unset, 0x20
                - otherwise, 0x10
    2b updated dstpos??
       add base vram address to this to get ???
    2b compressed data address packed to a word.
       decode as:
         cmpSrcPtr = (grpHeaderPtr & 0xFF8000) | (word)
   */
  Madou1MdCmpSubheader Madou1MdDecompressor::readSubheader(
      int initialSubheaderAddr) {
    if (verbose) {
      std::cout << "  *** Reading subheader at "
        << TStringConversion::intToString(rom.tell(),
                                          TStringConversion::baseHex)
        << std::endl;
    }
    
    Madou1MdCmpSubheader subheader;
    
    TByte cmpSettings = rom.readu8();
    
    if ((cmpSettings & 0x80) != 0)
      subheader.submode = Madou1MdCmpSubmodes::submode1;
    else
      subheader.submode = Madou1MdCmpSubmodes::submode0;
    
    if ((cmpSettings & 0x40) != 0)
      subheader.blockMode = Madou1MdBlockModes::locked;
    else
      subheader.blockMode = Madou1MdBlockModes::unlocked;
    
    subheader.userBlockSizeInPatterns = rom.readu8();
    if (subheader.userBlockSizeInPatterns == 0)
      subheader.userBlockSizeInPatterns = 0x100;
    
    subheader.dstOffset = rom.readu16be();
    
    subheader.srcAddr = rom.readu16be() | (initialSubheaderAddr & 0xFF8000);
    
    if (verbose) {
      std::cout
        << "    submode: "
        << TStringConversion::intToString(subheader.submode,
                                          TStringConversion::baseHex)
        << std::endl
        << "    blockMode: "
        << TStringConversion::intToString(subheader.blockMode,
                                          TStringConversion::baseHex)
        << std::endl
        << "    userBlockSizeInPatterns: "
        << TStringConversion::intToString(subheader.userBlockSizeInPatterns,
                                          TStringConversion::baseHex)
        << std::endl
        << "    dstOffset: "
        << TStringConversion::intToString(subheader.dstOffset,
                                          TStringConversion::baseHex)
        << std::endl
        << "    srcAddr: "
        << TStringConversion::intToString(subheader.srcAddr,
                                          TStringConversion::baseHex)
        << std::endl;
    }
    
    return subheader;
  }
  
  int Madou1MdDecompressor::getDefaultBlockSize(
      Madou1MdCmpModes::Madou1MdCmpMode mode,
      Madou1MdCmpSubmodes::Madou1MdCmpSubmode submode,
      bool expandedSizes) {
    int size;
    
    if (mode == Madou1MdCmpModes::mode0) {
      if (!expandedSizes) size = -1;
//      else size = (expandedSizes ? 0x20 : 0x10);
      else size = 0x10;
    }
    else {
      if (submode == Madou1MdCmpSubmodes::submode0) {
        size = 0x20;
      }
      else {
        size = 0x10;
      }
      
      if (expandedSizes) size *= 2;
    }
    
    return size;
  }


}
