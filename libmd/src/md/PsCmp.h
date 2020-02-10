#ifndef PSCMPMD_H
#define PSCMPMD_H


#include "util/TStream.h"

namespace Md {

class PsCmp {
public:
  static void cmpPs(BlackT::TStream& src, BlackT::TStream& dst,
                    int interleaving);
  static void decmpPs(BlackT::TStream& src, BlackT::TStream& dst,
                    int interleaving);
protected:
  static void decmpPsPlane(BlackT::TStream& src, BlackT::TStream& dst);
};


}


#endif
