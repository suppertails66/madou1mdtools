#include "md/MdPattern.h"
#include "util/TIfstream.h"
#include "util/TStream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TOpt.h"
#include "util/TFileManip.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "exception/TGenericException.h"
#include <vector>
#include <string>
#include <iostream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Md;

struct CredEvent {
  enum Type {
    type_null       = 0x0000,
    type_sendMap    = 0x0001,
    type_clearArea  = 0x0002
  };
  
  Type type;  // type of event
  int triggerTime;   // event's time, expressed in absolute frames from start
  string name;
  int x;
  int y;
  int w;
  int h;
  
  CredEvent()
    : type(type_null),
      triggerTime(0),
      x(0),
      y(0),
      w(0),
      h(0) { }
  
  void write(TStream& ofs) {
    ofs.writeu16be(triggerTime);
    ofs.writeu16be(type);
    switch (type) {
    case type_null:
      
      break;
    case type_sendMap:
      // write x/y/w/h
      ofs.writeu16be(x);
      ofs.writeu16be(y);
      ofs.writeu16be(w);
      ofs.writeu16be(h);
      
      // write size of map for skipping
//      ofs.writeu16be(w * h * 2);
      
      if (!TFileManip::fileExists(name)) {
        throw TGenericException(T_SRCANDLINE,
                                "CredEvent::write()",
                                string("Target map not found: ")
                                  + name);
      }
      
      // open rendered map and write to stream
      {
        TBufStream ifs;
        ifs.open(name.c_str());
        while (!ifs.eof()) ofs.put(ifs.get());
      }
      
      break;
    case type_clearArea:
      // write x/y/w/h
      ofs.writeu16be(x);
      ofs.writeu16be(y);
      ofs.writeu16be(w);
      ofs.writeu16be(h);
      break;
    default:
      throw TGenericException(T_SRCANDLINE,
                              "CredEvent::write()",
                              "Unknown event type");
      break;
    }
  }
  
  CredEvent& makeSendMap(
                    int triggerTime__,
                    std::string filebase,
                    int x__, int y__) {
    triggerTime = triggerTime__;
    type = type_sendMap;
    
    std::string mapFileName = "out/maps/" + filebase + ".bin";
    std::string grpFileName = "rsrc/credits/" + filebase + ".png";
    
    name = mapFileName;
    x = x__;
    y = y__;
    
    TGraphic grp;
    TPngConversion::RGBAPngToGraphic(grpFileName, grp);
    w = grp.w() / MdPattern::w;
    h = grp.h() / MdPattern::h;
    
    return *this;
  }
  
  CredEvent& makeClearArea(
                    int triggerTime__,
                    int x__, int y__, int w__, int h__) {
    triggerTime = triggerTime__;
    type = type_clearArea;
    
    x = x__;
    y = y__;
    w = w__;
    h = h__;
    
    return *this;
  }
  
/*  CredEvent& makeClearAreaFromGrp(std::string filebase,
                            int x__, int y__) {
    std::string mapFileName = "out/maps/" + filebase + ".bin";
    std::string grpFileName = "rsrc/credits/" + filebase + ".png";
    
    x = x__;
    y = y__;
    
    TGraphic grp;
    TPngConversion::RGBAPngToGraphic(grpFileName, grp);
    w = grp.w() / MdPattern::w;
    h = grp.h() / MdPattern::h;
    
    return *this;
  } */
};

struct CredEventPack {
  
  std::vector<CredEvent> events;
  
  void addEvent(const CredEvent& event) {
    events.push_back(event);
  }
  
  void write(TStream& ofs) {
    for (unsigned int i = 0; i < events.size(); i++) {
      events[i].write(ofs);
    }
    
    // terminator
    ofs.writeu16be(0xFFFF);
  }
  
};

struct CredSequence {
  
  CredEventPack events;
  CredEventPack cleanupEvents;
  
  void addEvent(const CredEvent& event) {
    events.addEvent(event);
    
    // add cleanup events for map sends
    if (event.type == CredEvent::type_sendMap) {
      cleanupEvents.addEvent(
        CredEvent().makeClearArea(0,
                                  event.x, event.y, event.w, event.h));
    }
  }
  
  void addEventNoCleanup(const CredEvent& event) {
    events.addEvent(event);
  }
  
  void addSendMap(int triggerTime, std::string filebase, int x, int y) {
    addEvent(CredEvent().makeSendMap(triggerTime, filebase, x, y));
  }
  
  void addCenteredSendMap(int triggerTime, std::string filebase, int y) {
    TGraphic grp;
    TPngConversion::RGBAPngToGraphic(
      string("rsrc/credits/") + filebase + ".png", grp);
    int w = grp.w() / MdPattern::w;
    int x = (40 - w) / 2;
    
    addSendMap(triggerTime, filebase, x, y);
  }
  
  void addSendMapNoCleanup(int triggerTime, std::string filebase, int x, int y) {
    addEventNoCleanup(CredEvent().makeSendMap(triggerTime, filebase, x, y));
  }
  
  void addCenteredSendMapNoCleanup(int triggerTime, std::string filebase, int y) {
    TGraphic grp;
    TPngConversion::RGBAPngToGraphic(
      string("rsrc/credits/") + filebase + ".png", grp);
    int w = grp.w() / MdPattern::w;
    int x = (40 - w) / 2;
    
    addSendMapNoCleanup(triggerTime, filebase, x, y);
  }
  
  void addClearArea(int triggerTime, int x, int y, int w, int h) {
    addEvent(CredEvent().makeClearArea(triggerTime, x, y, w, h));
  }
  
  void addClearAreaFromGrp(int triggerTime, std::string filebase, int x, int y) {
    TGraphic grp;
    TPngConversion::RGBAPngToGraphic(
      string("rsrc/credits/") + filebase + ".png", grp);
    int w = grp.w() / MdPattern::w;
    int h = grp.h() / MdPattern::h;
    
    addEvent(CredEvent().makeClearArea(triggerTime, x, y, w, h));
  }
  
  void addCenteredClearAreaFromGrp(int triggerTime, std::string filebase, int y) {
    TGraphic grp;
    TPngConversion::RGBAPngToGraphic(
      string("rsrc/credits/") + filebase + ".png", grp);
    int w = grp.w() / MdPattern::w;
    int h = grp.h() / MdPattern::h;
    int x = (40 - w) / 2;
    
    addEvent(CredEvent().makeClearArea(triggerTime, x, y, w, h));
  }
  
  void write(TStream& ofs) {
    TBufStream eventsOfs;
    TBufStream cleanupOfs;
    
    events.write(eventsOfs);
    cleanupEvents.write(cleanupOfs);
    
    // offsets to each event list
    ofs.writeu16be(4);
    ofs.writeu16be(4 + eventsOfs.size());
    
    // event lists
    eventsOfs.seek(0);
    while (!eventsOfs.eof()) ofs.put(eventsOfs.get());
    cleanupOfs.seek(0);
    while (!cleanupOfs.eof()) ofs.put(cleanupOfs.get());
  }
  
  void writeToFile(std::string filename) {
    TBufStream ofs;
    write(ofs);
    ofs.save(filename.c_str());
  }
  
};

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Madou Monogatari I hardcoded credits builder" << endl;
    cout << "Usage: "
         << argv[0] << " <inprefix> <outprefix>" << endl;
    
    return 0;
  }
  
  try {
  
    string inprefix = string(argv[1]);
    string outprefix = string(argv[2]);
    
    //==========================
    // 0
    //==========================
    
    CredSequence credits0;
//    credits0.addCenteredSendMap(      0, "credits_0-0",  8);
    credits0.addCenteredSendMapNoCleanup(    108, "credits_0-1", 18);
    credits0.addCenteredClearAreaFromGrp(  108+136+6, "credits_0-1", 18);
    credits0.writeToFile("out/credits/credits_seq_0.bin");
    
    //==========================
    // 1
    //==========================
    
    CredSequence credits1;
//    credits1.addCenteredSendMap(    0, "credits_1-0",  8);
    credits1.addCenteredSendMapNoCleanup(  177, "credits_1-1", 17);
    credits1.addCenteredClearAreaFromGrp(  177+217, "credits_1-1", 17);
    credits1.writeToFile("out/credits/credits_seq_1.bin");
    
    //==========================
    // 2
    //==========================
    
    CredSequence credits2a;
//    credits2a.addCenteredSendMapNoCleanup(    0, "credits_2-0",  8);
    credits2a.addCenteredSendMapNoCleanup(  123, "credits_2-1",  17);
    credits2a.addCenteredClearAreaFromGrp(  123+263, "credits_2-1", 17);
    credits2a.writeToFile("out/credits/credits_seq_2a.bin");
    
    CredSequence credits2b;
//    credits2b.addCenteredSendMap(  0, "credits_2-0",  8);
    credits2b.addCenteredSendMapNoCleanup(  101, "credits_2-2",  17);
    credits2b.addCenteredClearAreaFromGrp(  90+491, "credits_2-2", 17);
    credits2b.writeToFile("out/credits/credits_seq_2b.bin");
    
    //==========================
    // 3
    //==========================
    
    CredSequence credits3a;
//    credits3a.addCenteredSendMapNoCleanup(    0, "credits_3-0",  8);
    credits3a.addCenteredSendMapNoCleanup(  508, "credits_3-1",  17);
    credits3a.addCenteredClearAreaFromGrp(  508+135, "credits_3-1", 17);
    credits3a.writeToFile("out/credits/credits_seq_3a.bin");
    
    CredSequence credits3b;
    credits3b.addCenteredSendMapNoCleanup(  470, "credits_3-2",  17);
    credits3b.addCenteredClearAreaFromGrp(  470+255, "credits_3-2", 17);
    credits3b.writeToFile("out/credits/credits_seq_3b.bin");
    
    CredSequence credits3c;
//    credits3c.addCenteredSendMap(    0, "credits_3-0",  8);
    credits3c.writeToFile("out/credits/credits_seq_3c.bin");
    
    //==========================
    // 4
    //==========================
    
    CredSequence credits4a;
//    credits4a.addCenteredSendMapNoCleanup(    0, "credits_4-0",  8);
    credits4a.addCenteredSendMapNoCleanup(  85, "credits_4-1",  17);
    credits4a.addCenteredClearAreaFromGrp(  85+685, "credits_4-1", 17);
    credits4a.writeToFile("out/credits/credits_seq_4a.bin");
    
    CredSequence credits4b;
//    credits4b.addCenteredSendMap(    0, "credits_4-0",  8);
    credits4b.writeToFile("out/credits/credits_seq_4b.bin");
    
    //==========================
    // 5
    //==========================
    
    CredSequence credits5a;
//    credits5a.addCenteredSendMapNoCleanup(    0, "credits_5-0",  8);
    credits5a.addCenteredSendMapNoCleanup(  557, "credits_5-1",  17);
    credits5a.addCenteredClearAreaFromGrp(  557+121, "credits_5-1", 17);
    credits5a.writeToFile("out/credits/credits_seq_5a.bin");
    
    CredSequence credits5b;
//    credits5b.addCenteredSendMap(    0, "credits_5-0",  8);
    credits5b.addCenteredSendMapNoCleanup(  358, "credits_5-2",  16);
    credits5b.addCenteredClearAreaFromGrp(  358+179, "credits_5-2", 16);
    credits5b.writeToFile("out/credits/credits_seq_5b.bin");
    
    //==========================
    // 6
    //==========================
    
    CredSequence credits6;
//    credits6.addCenteredSendMap(    0, "credits_6-0",  8);
    credits6.writeToFile("out/credits/credits_seq_6.bin");
    
    //==========================
    // 7
    //==========================
    
    CredSequence credits7a;
//    credits7a.addCenteredSendMapNoCleanup(    0, "credits_7-0",  8);
    credits7a.addCenteredSendMapNoCleanup(  183, "credits_7-1",  18);
    credits7a.addCenteredClearAreaFromGrp(  183+302, "credits_7-1", 18);
    credits7a.writeToFile("out/credits/credits_seq_7a.bin");
    
    CredSequence credits7b;
    credits7b.addSendMapNoCleanup(    0, "credits_7-2", 16, 17);
    credits7b.addSendMapNoCleanup(  92, "credits_7-3", 16, 17);
    credits7b.addSendMapNoCleanup(  92+82, "credits_7-4", 16, 17);
    credits7b.addClearAreaFromGrp(  92+82+57, "credits_7-4", 16, 17);
    credits7b.writeToFile("out/credits/credits_seq_7b.bin");
    
    CredSequence credits7c;
//    credits7c.addCenteredSendMap(    0, "credits_7-0",  8);
    credits7c.addCenteredSendMapNoCleanup(    1, "credits_7-5",  17);
    credits7c.addCenteredSendMapNoCleanup(    1+144, "credits_7-6",  21);
    credits7c.addCenteredClearAreaFromGrp(  1+144+73+48, "credits_7-6", 21);
    credits7c.addCenteredClearAreaFromGrp(  1+144+73+48+35, "credits_7-5", 17);
    credits7c.writeToFile("out/credits/credits_seq_7c.bin");
    
//    CredSequence credits7c;
//    credits7d.addCenteredSendMap(    0, "credits_7-0",  8);
//    credits7d.writeToFile("out/credits/credits_seq_7d.bin");
    
    //==========================
    // 8
    //==========================
    
    CredSequence credits8;
//    credits8.addCenteredSendMap(    0, "credits_8-0",  8);
    credits8.addCenteredSendMapNoCleanup(  224, "credits_8-1",  17);
    credits8.addCenteredClearAreaFromGrp(  224+180, "credits_8-1", 17);
    credits8.writeToFile("out/credits/credits_seq_8.bin");
    
    //==========================
    // 9 227 439 710 905
    //==========================
    
    CredSequence credits9a;
//    credits9a.addCenteredSendMapNoCleanup(    0, "credits_9-0",  8);
    credits9a.addCenteredSendMapNoCleanup(  160+15, "credits_9-1",  17);
    credits9a.addCenteredClearAreaFromGrp(  160+208+15, "credits_9-1", 17);
    credits9a.writeToFile("out/credits/credits_seq_9a.bin");
    
    CredSequence credits9b;
    credits9b.addCenteredSendMapNoCleanup(   72-1, "credits_9-2",  11);
    credits9b.addCenteredSendMapNoCleanup(   72-1, "credits_9-3",  14);
    credits9b.addCenteredSendMapNoCleanup(   72-1, "credits_9-4",  17);
    credits9b.addCenteredSendMapNoCleanup(   72-1, "credits_9-5",  20);
    credits9b.addCenteredSendMapNoCleanup(   72-1, "credits_9-6",  23);
    credits9b.addCenteredClearAreaFromGrp(  72+314-1, "credits_9-2", 11);
    credits9b.addCenteredClearAreaFromGrp(  72+314-1, "credits_9-3", 14);
    credits9b.addCenteredClearAreaFromGrp(  72+314-1, "credits_9-4", 17);
    credits9b.addCenteredClearAreaFromGrp(  72+314-1, "credits_9-5", 20);
    credits9b.addCenteredClearAreaFromGrp(  72+314-1, "credits_9-6", 23);
    credits9b.writeToFile("out/credits/credits_seq_9b.bin");
    
    CredSequence credits9c;
    credits9c.addCenteredSendMapNoCleanup(  212, "credits_9-7",  17);
    credits9c.addCenteredClearAreaFromGrp(  212+272+15, "credits_9-7",  17);
//    credits9c.addCenteredClearAreaFromGrp(  212+272+190+8, "credits_9-0",  8);
    credits9c.writeToFile("out/credits/credits_seq_9c.bin");
    
    //==========================
    // NOTE: everything after 9 is newly added for the hack
    //==========================
    
    //==========================
    // 10
    //==========================
    
    CredSequence credits10;
    
    credits10.addCenteredSendMapNoCleanup(    0, "credits_10-0",  12);
    credits10.addCenteredClearAreaFromGrp(  180, "credits_10-0",  12);
    
    credits10.addCenteredSendMapNoCleanup(  240, "credits_10-1",  6);
    credits10.addCenteredSendMapNoCleanup(  240, "credits_10-2",  9);
    credits10.addCenteredSendMapNoCleanup(  240, "credits_10-3",  12);
    credits10.addCenteredSendMapNoCleanup(  240, "credits_10-4",  15);
    credits10.addCenteredSendMapNoCleanup(  240, "credits_10-5",  18);
    credits10.addCenteredSendMapNoCleanup(  240, "credits_10-6",  21);
    
    credits10.addCenteredClearAreaFromGrp(  540, "credits_10-1",  6);
    credits10.addCenteredClearAreaFromGrp(  540, "credits_10-2",  9);
    credits10.addCenteredClearAreaFromGrp(  540, "credits_10-3",  12);
    credits10.addCenteredClearAreaFromGrp(  540, "credits_10-4",  15);
    credits10.addCenteredClearAreaFromGrp(  540, "credits_10-5",  18);
    credits10.addCenteredClearAreaFromGrp(  540, "credits_10-6",  21);
/*    
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-7",  9);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-8",  12);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-9",  15);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-10",  18); */
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-7",  6);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-8",  9);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-9",  12);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-10",  15);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-11",  18);
    credits10.addCenteredSendMapNoCleanup(  600, "credits_10-12",  21);
    
/*    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-7",  9);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-8",  12);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-9",  15);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-10",  18); */
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-7",  6);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-8",  9);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-9",  12);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-10",  15);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-11",  18);
    credits10.addCenteredClearAreaFromGrp(  900, "credits_10-12",  21);
    
    
    credits10.writeToFile("out/credits/credits_seq_10.bin");
    
    //==========================
    // 11
    //==========================
    
//    CredSequence credits11;
//    credits11.writeToFile("out/credits/credits_seq_11.bin");
    
//    for (int i = 3; i < 12; i++) {
//      std::string num = TStringConversion::intToString(i);
//      CredSequence credits;
//      credits.writeToFile(string("out/credits/credits_seq_") + num + ".bin");
//    }
    
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
