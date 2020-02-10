IDIR := src
SRCDIR := src
ODIR := obj
LDIR :=

BLACKTDIR = ../blackt
LIBMDDIR = ../libmd
KENSDIR = ../kens

AR=ar
CXX=g++
# Compile only
CDEFINES = -DBLACKT_ENABLE_LIBPNG
#CLIBS = -lpng
CFLAGS = -std=gnu++11 -O2 -Wall -L${LIBMDDIR} -lmd -L${BLACKTDIR} -lblackt -L${KENSDIR} -lkens -lpng
CINCLUDES = -I${BLACKTDIR}/src -I${LIBMDDIR}/src -I${KENSDIR}/kens
CXXFLAGS=$(CFLAGS) $(CDEFINES) $(CINCLUDES) -I$(IDIR)

LIBDEPS := $(LIBMDDIR)/libmd.a $(BLACKTDIR)/libblackt.a $(KENSDIR)/libkens.a

TOOLSRCS := $(wildcard $(SRCDIR)/*.cpp)
TOOLSINDIR := $(patsubst %.cpp,%,$(TOOLSRCS))
TOOLS := $(notdir $(TOOLSINDIR))

.SECONDEXPANSION:

all: blackt libmd kens $(TOOLS)

blackt:
	cd ${BLACKTDIR} && $(MAKE) && cd $(CURDIR)

libmd:
	cd ${LIBMDDIR} && $(MAKE) && cd $(CURDIR)

kens:
	cd ${KENSDIR} && $(MAKE) && cd $(CURDIR)

$(TOOLS): $(SRCDIR)/$$@.cpp $(LIBDEPS)
	make blackt
	make libmd
	$(CXX) $(SRCDIR)/$@.cpp $(OBJ) -o $(notdir $@) $(CXXFLAGS)

.PHONY: blackt libmd kens cleanme clean

cleanme:
	rm -f $(TOOLS)

clean: cleanme
#	rm -f $(LIB)
#	rm -rf $(ODIR)
	cd ${BLACKTDIR} && $(MAKE) clean && cd $(CURDIR)
	cd ${LIBMDDIR} && $(MAKE) clean && cd $(CURDIR)
	cd ${KENSDIR} && $(MAKE) clean && cd $(CURDIR)