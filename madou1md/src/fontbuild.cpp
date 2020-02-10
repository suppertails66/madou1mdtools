#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TIniFile.h"
#include "util/TTwoDArray.h"
#include "util/TByte.h"
#include <vector>
#include <string>
#include <iostream>
#include <cctype>

// if nonzero, generates a visual representation of the kerning matrix
// in the output directory
#define OUTPUT_PREVIEW_GRAPHIC 0

using namespace std;
using namespace BlackT;
//using namespace Sms;

typedef TTwoDArray<char> KerningMatrix;

const static int upperCaseBase = 0x0B;
const static int lowerCaseBase = 0x25;

const static int periodIndex = 0x3F;
const static int commaIndex = 0x40;
const static int apostropheIndex = 0x43;
const static int semicolonIndex = 0x44;
const static int colonIndex = 0x4C;

bool getIntIfExists(int* dst, const TIniFile& ini, std::string section, std::string key) {
  if (dst == NULL) return false;
  if (!ini.hasSection(section)) return false;
  if (!ini.hasKey(section, key)) return false;
  
  *dst = TStringConversion::stringToInt(ini.valueOfKey(section, key));
  return true;
}

bool getBoolIfExists(bool* dst, const TIniFile& ini, std::string section, std::string key) {
  if (dst == NULL) return false;
  if (!ini.hasSection(section)) return false;
  if (!ini.hasKey(section, key)) return false;
  
  *dst = (TStringConversion::stringToInt(ini.valueOfKey(section, key)) != 0);
  return true;
}

struct CharData {
  TGraphic grp;
  int glyphWidth;
  int advanceWidth;
  bool noKerningIfFirst;
  bool noKerningIfSecond;
  bool has_firstKerningAgainstShortChars;
  int firstKerningAgainstShortChars;
  bool has_secondKerningAgainstShortChars;
  int secondKerningAgainstShortChars;
  
  CharData()
    : glyphWidth(-1),
      advanceWidth(-1),
      noKerningIfFirst(false),
      noKerningIfSecond(false),
      has_firstKerningAgainstShortChars(false),
      firstKerningAgainstShortChars(0),
      has_secondKerningAgainstShortChars(false),
      secondKerningAgainstShortChars(0) { }
  
  void readFromIni(TIniFile& ini, std::string& section) {
    if (!ini.hasSection(section)) return;
    
    getIntIfExists(&glyphWidth, ini, section, "glyphWidth");
    getIntIfExists(&advanceWidth, ini, section, "advanceWidth");
    getBoolIfExists(&noKerningIfFirst, ini, section, "noKerningIfFirst");
    getBoolIfExists(&noKerningIfSecond, ini, section, "noKerningIfSecond");
    has_firstKerningAgainstShortChars = getIntIfExists(
      &firstKerningAgainstShortChars, ini, section,
      "firstKerningAgainstShortChars");
    has_secondKerningAgainstShortChars = getIntIfExists(
      &secondKerningAgainstShortChars, ini, section,
      "secondKerningAgainstShortChars");
  }
};

string asHex(int num, int padding) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < padding) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

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

bool isNotBlackOrTransparent(const TGraphic& grp, int x, int y) {
  if (x < 0) return false;
  else if (x >= grp.w()) return false;
  else if (y < 0) return false;
  else if (y >= grp.h()) return false;

  TColor color = grp.getPixel(x, y);
  if ((color.a() == TColor::fullAlphaOpacity)
      && ((color.r() != 0) || (color.g() != 0) || (color.b() != 0))) {
    return true;
  }
  else {
    // transparent
    return false;
  }
}

int getPixelIndex(const TGraphic& grp, int x, int y,
                 int bgIndex, int solidIndex) {
  TColor color = grp.getPixel(x, y);
  if ((color.a() == TColor::fullAlphaOpacity)
      && ((color.r() != 0) || (color.g() != 0) || (color.b() != 0))) {
    // solid
    return solidIndex;
  }
  else {
    // transparent
    return bgIndex;
  }
}

void graphicTo4bpp(const TGraphic& grp, int baseX, int baseY, int w, int h,
                   TStream& ofs,
                   int bgIndex, int solidIndex) {
  bool hasOddWidth = (w & 1) != 0;
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i += 2) {
      int x = baseX + i;
      int y = baseY + j;
      
      int index1 = getPixelIndex(grp, x, y, bgIndex, solidIndex);
      
      int index2 = 0;
      if (!(hasOddWidth && (i == w))) {
        index2 = getPixelIndex(grp, x + 1, y, bgIndex, solidIndex);
      }
      
      TByte output = 0x00;
      output |= (index1 << 4);
      output |= (index2);
      ofs.put(output);
    }
  }
}

int computeKerning(const CharData& first, const CharData& second) {
  // do not apply kerning if first character is blank
  bool firstHasSolidPixel = false;
  for (int j = 0; j < first.grp.h(); j++) {
    for (int i = 0; i < first.grp.w(); i++) {
      if (isNotBlackOrTransparent(first.grp, i, j)) {
        firstHasSolidPixel = true;
        break;
      }
    }
  }
  if (!firstHasSolidPixel) return 0;

  int kerning = 0;
//  for (int i = first.advanceWidth - 1; i >= 1; i--) {
  bool done = false;
  bool secondHasSolidPixel = false;
  for (int k = 1; k < first.advanceWidth; k++) {
    for (int i = 0; i < k; i++) {
      for (int j = 0; j < second.grp.h(); j++) {
//        int shift = -k;
        
        if (isNotBlackOrTransparent(second.grp, i, j)) {
          secondHasSolidPixel = true;
          
          int firstBaseX = first.advanceWidth - k + i;
          int firstBaseY = j;
//          std::cerr << "check: " << endl
//            << "  second: " << i << " " << j << std::endl
//            << "  first:  " << firstBaseX << " " << firstBaseY << endl;
          
          if (false   
//              || isNotBlackOrTransparent(first.grp, firstBaseX - 1, firstBaseY - 1)
              || isNotBlackOrTransparent(first.grp, firstBaseX, firstBaseY - 1)
//              || isNotBlackOrTransparent(first.grp, firstBaseX + 1, firstBaseY - 1)
              || isNotBlackOrTransparent(first.grp, firstBaseX - 1, firstBaseY)
              || isNotBlackOrTransparent(first.grp, firstBaseX, firstBaseY)
              || isNotBlackOrTransparent(first.grp, firstBaseX + 1, firstBaseY)
//              || isNotBlackOrTransparent(first.grp, firstBaseX - 1, firstBaseY + 1)
              || isNotBlackOrTransparent(first.grp, firstBaseX, firstBaseY + 1)
//              || isNotBlackOrTransparent(first.grp, firstBaseX + 1, firstBaseY + 1)
             ) {
//            std::cerr << "done" << std::endl;
            done = true;
          }
        }
        
        if (done) break;
      }
      
      if (done) break;
    }
    
    if (done) break;
    else {
      --kerning;
//      std::cerr << "kerning changed to " << kerning << std::endl;
    }
  }
  
  // do not apply kerning if second character is blank
  if (!secondHasSolidPixel) return 0;
  
  // if we did not detect any collision even after moving the second
  // character all the way to the left... well, all we can do is
  // guess what will actually look good
//  if (!done) return (kerning >= 0) ? 0 : kerning + 1;
  if (!done) return 0;
  
  return kerning;
}

std::vector<int> getShortCharRange() {
  std::vector<int> result;
  result.push_back(lowerCaseBase + (unsigned int)('a' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('c' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('e' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('g' - 'a'));
//  result.push_back(lowerCaseBase + (unsigned int)('i' - 'a'));
//  result.push_back(lowerCaseBase + (unsigned int)('j' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('m' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('n' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('o' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('p' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('q' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('r' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('s' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('u' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('v' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('w' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('x' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('y' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('z' - 'a'));
  return result;
}

std::vector<int> getbLikeCharRange() {
  std::vector<int> result;
  result.push_back(lowerCaseBase + (unsigned int)('b' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('h' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('k' - 'a'));
  return result;
}

std::vector<int> getdLikeCharRange() {
  std::vector<int> result;
  result.push_back(lowerCaseBase + (unsigned int)('d' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('j' - 'a'));
  return result;
}

std::vector<int> getSerifsRightRange() {
  std::vector<int> result;
  result.push_back(lowerCaseBase + (unsigned int)('A' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('G' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('H' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('I' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('M' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('N' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('R' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('U' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('V' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('W' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('X' - 'A'));
  result.push_back(lowerCaseBase + (unsigned int)('Y' - 'A'));
  
  result.push_back(lowerCaseBase + (unsigned int)('a' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('d' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('g' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('h' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('i' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('l' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('m' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('n' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('q' - 'a'));
//  result.push_back(lowerCaseBase + (unsigned int)('t' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('u' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('v' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('w' - 'a'));
//  result.push_back(lowerCaseBase + (unsigned int)('x' - 'a'));
  result.push_back(lowerCaseBase + (unsigned int)('y' - 'a'));
  return result;
}

void setFirstKerningAgainstIndex(
    KerningMatrix& kerningMatrix, int first, int kerning,
    int index) {
  kerningMatrix.data(index, first) = kerning;
}

void setSecondKerningAgainstIndex(
    KerningMatrix& kerningMatrix, int second, int kerning,
    int index) {
  kerningMatrix.data(second, index) = kerning;
}

void setFirstKerningAgainstString(
    KerningMatrix& kerningMatrix, int first, int kerning,
    std::string str) {
  for (int i = 0; i < str.size(); i++) {
    char c = str[i];
    int index = -1;
    if (islower(c)) index = 0x1B + (unsigned char)(c - 'a');
    else if (isupper(c)) index = 0x01 + (unsigned char)(c - 'A');
    
    setFirstKerningAgainstIndex(kerningMatrix, first, kerning, index);
  }
}

void setSecondKerningAgainstString(
    KerningMatrix& kerningMatrix, int second, int kerning,
    std::string str) {
  for (int i = 0; i < str.size(); i++) {
    char c = str[i];
    int index = -1;
    if (islower(c)) index = 0x1B + (unsigned char)(c - 'a');
    else if (isupper(c)) index = 0x01 + (unsigned char)(c - 'A');
    
    setSecondKerningAgainstIndex(kerningMatrix, second, kerning, index);
  }
}

void setFirstKerningAgainstRange(
    KerningMatrix& kerningMatrix, int first, int kerning,
    std::vector<int> range) {
  for (int i = 0; i < range.size(); i++) {
    setFirstKerningAgainstIndex(kerningMatrix, first, kerning, range[i]);
  }
}

void setSecondKerningAgainstRange(
    KerningMatrix& kerningMatrix, int second, int kerning,
    std::vector<int> range) {
  for (int i = 0; i < range.size(); i++) {
    setSecondKerningAgainstIndex(kerningMatrix, second, kerning, range[i]);
  }
}

void setFirstKerningAgainstShortChars(
    KerningMatrix& kerningMatrix, int first, int kerning) {
  setFirstKerningAgainstRange(
    kerningMatrix, first, kerning, getShortCharRange());
}

void setSecondKerningAgainstShortChars(
    KerningMatrix& kerningMatrix, int second, int kerning) {
  setSecondKerningAgainstRange(
    kerningMatrix, second, kerning, getShortCharRange());
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    std::cout << "16x16 font builder"
      << std::endl;
    std::cout << "Usage: " << argv[0] << " [inprefix] [outprefix]" << std::endl;
    
    return 0;
  }
  
  std::string inprefix = std::string(argv[1]);
  std::string outprefix = std::string(argv[2]);
  
  TIniFile index;
  index.readFile(inprefix + "index.txt");
  
  TGraphic sheet;
  TPngConversion::RGBAPngToGraphic(inprefix + "sheet.png", sheet);
  
  int numChars = TStringConversion::stringToInt(
    index.valueOfKey("Properties", "numChars"));
  int charsPerRow = TStringConversion::stringToInt(
    index.valueOfKey("Properties", "charsPerRow"));
  int gridW = TStringConversion::stringToInt(
    index.valueOfKey("Properties", "gridW"));
  int gridH = TStringConversion::stringToInt(
    index.valueOfKey("Properties", "gridH"));
  
  TBufStream ofsFont;
  TBufStream ofsCharTable;
  
  std::vector<CharData> charData;
  
  for (int k = 0; k < numChars; k++) {
    int rowNum = k / charsPerRow;
    int colNum = k % charsPerRow;
    int baseX = colNum * gridW;
    int baseY = rowNum * gridH;
    
//    std::string sectionNumStr = TStringConversion::intToString(k);
//    while (sectionNumStr.size() < 5)
//      sectionNumStr = std::string("0") + sectionNumStr;
    
    std::string sectionNumStr = asHex(k, 4);
    std::string sectionName = std::string("char") + sectionNumStr;
    
    CharData data;
/*    data.glyphWidth = glyphWidth;
    data.advanceWidth = advanceWidth;
    data.noKerningIfFirst = false;
    data.noKerningIfSecond = false;
    if (charHasDefinition && index.hasKey(sectionName, "noKerningIfFirst"))
      data.noKerningIfFirst =
        (TStringConversion::stringToInt(
          index.valueOfKey(sectionName, "noKerningIfFirst")) != 0);
    if (charHasDefinition && index.hasKey(sectionName, "noKerningIfSecond"))
      data.noKerningIfSecond =
        (TStringConversion::stringToInt(
          index.valueOfKey(sectionName, "noKerningIfSecond")) != 0); */
    data.readFromIni(index, sectionName);
    data.grp.resize(gridW, gridH);
    data.grp.clearTransparent();
    data.grp.copy(sheet, TRect(0, 0, 0, 0), TRect(baseX, baseY, gridW, gridH));
    
/*    int glyphWidth = TStringConversion::stringToInt(
      index.valueOfKey(sectionName, "glyphWidth"));
    int advanceWidth = TStringConversion::stringToInt(
      index.valueOfKey(sectionName, "advanceWidth")); */
      
    bool charHasDefinition = index.hasSection(sectionName);
    
//    int glyphWidth = -1;
//    int advanceWidth = -1;
    
//    getIntIfExists(&glyphWidth, index, sectionName, "glyphWidth");
//    getIntIfExists(&glyphWidth, index, sectionName, "advanceWidth");
    
    if ((data.glyphWidth == -1)) {
      // find rightmost opaque pixel
      int width = -1;
      for (int j = 0; j < gridH; j++) {
        for (int i = 0; i < gridW; i++) {
          TColor color = sheet.getPixel(baseX + i, baseY + j);
          if ((color.a() == TColor::fullAlphaOpacity)
              && ((color.r() != 0) || (color.g() != 0) || (color.b() != 0))) {
            if (i > width) width = i;
          }
        }
      }
      
      if (width != -1) data.glyphWidth = width + 1;
      else data.glyphWidth = 0;
      
//      if (data.advanceWidth == -1) data.advanceWidth = data.glyphWidth + 1;
    }
    
    if ((data.advanceWidth == -1)) {
      data.advanceWidth = data.glyphWidth + 1;
    }
    
    TBufStream top(64);
    TBufStream bottom(64);
    // use 0 as background color -- the real one is 1, but this way we can
    // init the buffers to 1 and OR non-transparent pixels onto them
    graphicTo4bpp(sheet, baseX, baseY,
                  16, 8, top, 0x0, 0xF);
    graphicTo4bpp(sheet, baseX, baseY + 8,
                  16, 8, bottom, 0x0, 0xF);
    
    top.seek(0);
    bottom.seek(0);
//    ofsFont.writeFrom(top, top.size());
//    ofsFont.writeFrom(bottom, bottom.size());
    // add 16px of padding after each row.
    // this allows us to slightly optimize the routine that
    // reads in the source data (by being able to "over-read" data
    // without worrying about accidentally getting pixels from the
    // data that follows)
    for (int i = 0; i < 8; i++) {
      ofsFont.writeFrom(top, 8);
      for (int i = 0; i < 8; i++) ofsFont.put(0);
    }
    for (int i = 0; i < 8; i++) {
      ofsFont.writeFrom(bottom, 8);
      for (int i = 0; i < 8; i++) ofsFont.put(0);
    }
    
    // now write the character again, but left-shifted by a nybble
    top.seek(0);
    bottom.seek(0);
    for (int j = 0; j < 8; j++) {
      for (int i = 0; i < 8; i++) {
        TByte value = (top.get() & 0x0F) << 4;
        if (i != 7) value |= (top.peek() & 0xF0) >> 4;
        ofsFont.put(value);
      }
      for (int i = 0; i < 8; i++) ofsFont.put(0);
    }
    for (int j = 0; j < 8; j++) {
      for (int i = 0; i < 8; i++) {
        TByte value = (bottom.get() & 0x0F) << 4;
        if (i != 7) value |= (bottom.peek() & 0xF0) >> 4;
        ofsFont.put(value);
      }
      for (int i = 0; i < 8; i++) ofsFont.put(0);
    }
    
    // each character is followed by a copy of itself but with all bytes
    // shifted left by one position, allowing the odd addresses to be
    // accessed as longs via a simple addition beforehand
    top.seek(0);
    bottom.seek(0);
    for (int i = 0; i < 8; i++) {
      top.get();
      ofsFont.writeFrom(top, 7);
      for (int i = 0; i < 9; i++) ofsFont.put(0);
    }
    for (int i = 0; i < 8; i++) {
      bottom.get();
      ofsFont.writeFrom(bottom, 7);
      for (int i = 0; i < 9; i++) ofsFont.put(0);
    }
    
    // now write the character again, but left-shifted by 3 nybbles
    top.seek(0);
    bottom.seek(0);
    for (int j = 0; j < 8; j++) {
      top.get();
      for (int i = 0; i < 7; i++) {
        TByte value = (top.get() & 0x0F) << 4;
        if (i != 6) value |= (top.peek() & 0xF0) >> 4;
        ofsFont.put(value);
      }
      for (int i = 0; i < 9; i++) ofsFont.put(0);
    }
    for (int j = 0; j < 8; j++) {
      bottom.get();
      for (int i = 0; i < 7; i++) {
        TByte value = (bottom.get() & 0x0F) << 4;
        if (i != 6) value |= (bottom.peek() & 0xF0) >> 4;
        ofsFont.put(value);
      }
      for (int i = 0; i < 9; i++) ofsFont.put(0);
    }
    
    ofsCharTable.writeu8(data.glyphWidth);
    ofsCharTable.writeu8(data.advanceWidth);
    
    charData.push_back(data);
  }
  
  ofsFont.save((outprefix + "font.bin").c_str());
  ofsCharTable.save((outprefix + "chartable.bin").c_str());
  
  KerningMatrix kerningMatrix(charData.size(), charData.size());
#if OUTPUT_PREVIEW_GRAPHIC
  TGraphic output(charData.size() * gridW * 2, charData.size() * gridH);
//  output.clearTransparent();
  output.clear(TColor(0, 0, 0, TColor::fullAlphaOpacity));
#endif
  for (int j = 0; j < charData.size(); j++) {
    for (int i = 0; i < charData.size(); i++) {
      int firstIndex = j;
      int secondIndex = i;
      
      CharData& first = charData[firstIndex];
      CharData& second = charData[secondIndex];
      
      int kerning;
      if (first.noKerningIfFirst) kerning = 0;
      else if (second.noKerningIfSecond) kerning = 0;
      else kerning = computeKerning(first, second);
      
      kerningMatrix.data(i, j) = kerning;
    }
  }
  
  // apply special kerning rules
  for (int i = 0; i < charData.size(); i++) {
    CharData& data = charData[i];
    
    if (data.has_firstKerningAgainstShortChars) {
      setFirstKerningAgainstShortChars(
        kerningMatrix, i, data.firstKerningAgainstShortChars);
    }
    
    if (data.has_secondKerningAgainstShortChars) {
      setSecondKerningAgainstShortChars(
        kerningMatrix, i, data.secondKerningAgainstShortChars);
    }
  }
  // hardcoded kerning
  
  // 't
  setFirstKerningAgainstIndex(kerningMatrix,
    apostropheIndex, -1,
    lowerCaseBase + (unsigned int)('t' - 'a'));
  
  // 'm
//  setFirstKerningAgainstIndex(kerningMatrix,
//    0x43, -1,
//    lowerCaseBase + (unsigned int)('m' - 'a'));
  
  // Eg
  setFirstKerningAgainstIndex(kerningMatrix,
    upperCaseBase + (unsigned int)('E' - 'A'), -1,
    lowerCaseBase + (unsigned int)('g' - 'a'));
  
  // St
  setFirstKerningAgainstIndex(kerningMatrix,
    upperCaseBase + (unsigned int)('S' - 'A'), -1,
    lowerCaseBase + (unsigned int)('t' - 'a'));
  
  // to
/*  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('t' - 'a'), -1,
    lowerCaseBase + (unsigned int)('o' - 'a'));
  
  // te
  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('t' - 'a'), -1,
    lowerCaseBase + (unsigned int)('e' - 'a'));
  
  // fo
  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('f' - 'a'), -1,
    lowerCaseBase + (unsigned int)('o' - 'a'));
  
  // fe
  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('f' - 'a'), -1,
    lowerCaseBase + (unsigned int)('e' - 'a')); */
  
  // for old serif font
/*if (false) {
  // hardcoded kerning
  
  // up
//  setFirstKerningAgainstIndex(kerningMatrix,
//    lowerCaseBase + (unsigned int)('u' - 'a'), -1,
//    lowerCaseBase + (unsigned int)('p' - 'a'));
  
  // an
//  setFirstKerningAgainstIndex(kerningMatrix,
//    lowerCaseBase + (unsigned int)('a' - 'a'), -2,
//    lowerCaseBase + (unsigned int)('n' - 'a'));
  
  // hi
//  setFirstKerningAgainstIndex(kerningMatrix,
//    lowerCaseBase + (unsigned int)('h' - 'a'), -2,
//    lowerCaseBase + (unsigned int)('i' - 'a'));
  
  // in
//  setFirstKerningAgainstIndex(kerningMatrix,
//    lowerCaseBase + (unsigned int)('i' - 'a'), -2,
//    lowerCaseBase + (unsigned int)('n' - 'a'));
  
  // in
//  setFirstKerningAgainstIndex(kerningMatrix,
//    lowerCaseBase + (unsigned int)('i' - 'a'), -1,
//    lowerCaseBase + (unsigned int)('n' - 'a'));
  
  // im
//  setFirstKerningAgainstIndex(kerningMatrix,
//    lowerCaseBase + (unsigned int)('i' - 'a'), -1,
//    lowerCaseBase + (unsigned int)('m' - 'a'));
  
  // i*
  setFirstKerningAgainstString(kerningMatrix,
    lowerCaseBase + (unsigned int)('i' - 'a'), -1,
    "ADEFHIKLMNRXbhiklmnpruvw"
    );
  // *i
  setSecondKerningAgainstString(kerningMatrix,
    lowerCaseBase + (unsigned int)('i' - 'a'), -1,
    "AGHIKMNRXadghilmnquvw"
    );
  
  // l*
  setFirstKerningAgainstString(kerningMatrix,
    lowerCaseBase + (unsigned int)('l' - 'a'), -1,
    "ADEFHIKLMNRXbhiklmnpruvw"
    );
  // *l
  setSecondKerningAgainstString(kerningMatrix,
    lowerCaseBase + (unsigned int)('l' - 'a'), -1,
    "AGHIKMNRXadghilmnquvw"
    );
  
  // an
  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('a' - 'a'), -2,
    lowerCaseBase + (unsigned int)('n' - 'a'));
  
  // qu
  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('q' - 'a'), -2,
    lowerCaseBase + (unsigned int)('u' - 'a'));
  
  // wn
  setFirstKerningAgainstIndex(kerningMatrix,
    lowerCaseBase + (unsigned int)('w' - 'a'), -1,
    lowerCaseBase + (unsigned int)('n' - 'a'));
  
  //=========================
  // apostrophe
  //=========================
  
  // 'd
  setFirstKerningAgainstIndex(kerningMatrix,
    apostropheIndex, -1,
    lowerCaseBase + (unsigned int)('d' - 'a'));
  
  // 't
  setFirstKerningAgainstIndex(kerningMatrix,
    apostropheIndex, -1,
    lowerCaseBase + (unsigned int)('t' - 'a'));
  
  // t'
  setSecondKerningAgainstIndex(kerningMatrix,
    apostropheIndex, -1,
    lowerCaseBase + (unsigned int)('t' - 'a'));
  
  //=========================
  // comma
  //=========================
  
  // F,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    upperCaseBase + (unsigned int)('F' - 'A'));
  
  // J,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    upperCaseBase + (unsigned int)('J' - 'A'));
  
  // P,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    upperCaseBase + (unsigned int)('P' - 'A'));
  
  // T,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    upperCaseBase + (unsigned int)('T' - 'A'));
  
  // U,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    upperCaseBase + (unsigned int)('U' - 'A'));
  
  // V,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -2,
    upperCaseBase + (unsigned int)('V' - 'A'));
  
  // W,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -2,
    upperCaseBase + (unsigned int)('W' - 'A'));
  
  // Y,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    upperCaseBase + (unsigned int)('Y' - 'A'));
  
  // f,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -2,
    lowerCaseBase + (unsigned int)('f' - 'a'));
  
  // g,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    lowerCaseBase + (unsigned int)('g' - 'a'));
  
  // q,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    lowerCaseBase + (unsigned int)('q' - 'a'));
  
  // r,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -1,
    lowerCaseBase + (unsigned int)('r' - 'a'));
  
  // v,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -2,
    lowerCaseBase + (unsigned int)('v' - 'a'));
  
  // w,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -2,
    lowerCaseBase + (unsigned int)('w' - 'a'));
  
  // y,
  setSecondKerningAgainstIndex(kerningMatrix,
    commaIndex, -2,
    lowerCaseBase + (unsigned int)('y' - 'a'));
  
  //=========================
  // period
  //=========================
  
  // F.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    upperCaseBase + (unsigned int)('F' - 'A'));
  
  // J.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    upperCaseBase + (unsigned int)('J' - 'A'));
  
  // P.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    upperCaseBase + (unsigned int)('P' - 'A'));
  
  // T.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    upperCaseBase + (unsigned int)('T' - 'A'));
  
  // U.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    upperCaseBase + (unsigned int)('U' - 'A'));
  
  // V.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -2,
    upperCaseBase + (unsigned int)('V' - 'A'));
  
  // W.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -2,
    upperCaseBase + (unsigned int)('W' - 'A'));
  
  // Y.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    upperCaseBase + (unsigned int)('Y' - 'A'));
  
  // f.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -2,
    lowerCaseBase + (unsigned int)('f' - 'a'));
  
  // g.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    lowerCaseBase + (unsigned int)('g' - 'a'));
  
  // q.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    lowerCaseBase + (unsigned int)('q' - 'a'));
  
  // r.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -1,
    lowerCaseBase + (unsigned int)('r' - 'a'));
  
  // v.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -2,
    lowerCaseBase + (unsigned int)('v' - 'a'));
  
  // w.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -2,
    lowerCaseBase + (unsigned int)('w' - 'a'));
  
  // y.
  setSecondKerningAgainstIndex(kerningMatrix,
    periodIndex, -2,
    lowerCaseBase + (unsigned int)('y' - 'a'));
  
  //=========================
  // semicolon
  //=========================
  
  // W;
  setSecondKerningAgainstIndex(kerningMatrix,
    semicolonIndex, -1,
    upperCaseBase + (unsigned int)('W' - 'A'));
  
  // V;
  setSecondKerningAgainstIndex(kerningMatrix,
    semicolonIndex, -1,
    upperCaseBase + (unsigned int)('V' - 'A'));
  
  // Y;
  setSecondKerningAgainstIndex(kerningMatrix,
    semicolonIndex, -1,
    upperCaseBase + (unsigned int)('Y' - 'A'));
  
  //=========================
  // colon
  //=========================
  
  // W:
  setSecondKerningAgainstIndex(kerningMatrix,
    colonIndex, -1,
    upperCaseBase + (unsigned int)('W' - 'A'));
  
  // V:
  setSecondKerningAgainstIndex(kerningMatrix,
    colonIndex, -1,
    upperCaseBase + (unsigned int)('V' - 'A'));
  
  // Y:
  setSecondKerningAgainstIndex(kerningMatrix,
    colonIndex, -1,
    upperCaseBase + (unsigned int)('Y' - 'A'));
} */
  // done
  
  TBufStream kerningMatrixOfs;
  for (int j = 0; j < charData.size(); j++) {
    for (int i = 0; i < charData.size(); i++) {
//      kerningMatrix.data(i, j) = 0;
      kerningMatrixOfs.put(kerningMatrix.data(i, j));
    }
  }
  
#if OUTPUT_PREVIEW_GRAPHIC
  for (int j = 0; j < charData.size(); j++) {
    for (int i = 0; i < charData.size(); i++) {
      int firstIndex = j;
      int secondIndex = i;
      
      int x = (gridW * 2) * i;
      int y = gridH * j;
      
      CharData& first = charData[firstIndex];
      CharData& second = charData[secondIndex];
      
      output.blit(first.grp, TRect(x, y, 0, 0));
      output.blit(second.grp,
        TRect(x + first.advanceWidth + kerningMatrix.data(i, j), y, 0, 0));
    }
  }
  
  TPngConversion::graphicToRGBAPng((outprefix + "kerning.png"), output);
#endif
  kerningMatrixOfs.save((outprefix + "kerning.bin").c_str());
  
  return 0;
}
