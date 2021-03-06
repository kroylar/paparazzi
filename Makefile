# Hey Emacs, this is a -*- makefile -*-
#
#   Copyright (C) 2004 Pascal Brisset Antoine Drouin
#
# This file is part of paparazzi.
#
# paparazzi is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# paparazzi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with paparazzi; see the file COPYING.  If not, write to
# the Free Software Foundation, 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

# The default is to produce a quiet echo of compilation commands
# Launch with "make Q=''" to get full echo
Q=@

ifeq ($(Q),@)
MAKEFLAGS += --no-print-directory
endif

PAPARAZZI_SRC=$(shell pwd)
empty=
space=$(empty) $(empty)
ifneq ($(findstring $(space),$(PAPARAZZI_SRC)),)
  $(error No fucking spaces allowed in the current directory name)
endif
ifeq ($(PAPARAZZI_HOME),)
PAPARAZZI_HOME=$(PAPARAZZI_SRC)
endif

# export the PAPARAZZI environment to sub-make
export PAPARAZZI_SRC
export PAPARAZZI_HOME

OCAML=$(shell which ocaml)
OCAMLRUN=$(shell which ocamlrun)
BUILD_DATETIME:=$(shell date +%Y%m%d-%H%M%S)

#
# define some paths
#
LIB=sw/lib
STATICINCLUDE =$(PAPARAZZI_HOME)/var/include
CONF=$(PAPARAZZI_SRC)/conf
AIRBORNE=sw/airborne
SIMULATOR=sw/simulator
MULTIMON=sw/ground_segment/multimon
COCKPIT=sw/ground_segment/cockpit
TMTC=sw/ground_segment/tmtc
TOOLS=$(PAPARAZZI_SRC)/sw/tools
EXT=sw/ext

#
# build some stuff in subdirs
# nothing should depend on these...
#
PPRZCENTER=sw/supervision
MISC=sw/ground_segment/misc
LOGALIZER=sw/logalizer

SUBDIRS = $(PPRZCENTER) $(MISC) $(LOGALIZER)

#
# xml files used as input for header generation
#
MESSAGES_XML = $(CONF)/messages.xml
UBX_XML = $(CONF)/ubx.xml
MTK_XML = $(CONF)/mtk.xml
XSENS_XML = $(CONF)/xsens_MTi-G.xml

#
# generated header files
#
MESSAGES_H=$(STATICINCLUDE)/messages.h
MESSAGES2_H=$(STATICINCLUDE)/messages2.h
UBX_PROTOCOL_H=$(STATICINCLUDE)/ubx_protocol.h
MTK_PROTOCOL_H=$(STATICINCLUDE)/mtk_protocol.h
XSENS_PROTOCOL_H=$(STATICINCLUDE)/xsens_protocol.h
DL_PROTOCOL_H=$(STATICINCLUDE)/dl_protocol.h
DL_PROTOCOL2_H=$(STATICINCLUDE)/dl_protocol2.h
ABI_MESSAGES_H=$(STATICINCLUDE)/abi_messages.h

GEN_HEADERS = $(MESSAGES_H) $(MESSAGES2_H) $(UBX_PROTOCOL_H) $(MTK_PROTOCOL_H) $(XSENS_PROTOCOL_H) $(DL_PROTOCOL_H) $(DL_PROTOCOL2_H) $(ABI_MESSAGES_H)


all: ground_segment ext lpctools

print_build_version:
	@echo "------------------------------------------------------------"
	@echo "Building Paparazzi version" $(shell ./paparazzi_version)
	@echo "------------------------------------------------------------"

update_google_version:
	-$(MAKE) -C data/maps

conf: conf/conf.xml conf/control_panel.xml conf/maps.xml

conf/%.xml :conf/%.xml.example
	[ -L $@ ] || [ -f $@ ] || cp $< $@


ground_segment: print_build_version update_google_version conf lib subdirs commands static

static: cockpit tmtc tools sim_static static_h

lib:
	$(MAKE) -C $(LIB)/ocaml

multimon:
	$(MAKE) -C $(MULTIMON)

cockpit: lib
	$(MAKE) -C $(COCKPIT)

tmtc: lib cockpit multimon
	$(MAKE) -C $(TMTC)

tools: lib
	$(MAKE) -C $(TOOLS)

sim_static: lib
	$(MAKE) -C $(SIMULATOR)

ext:
	$(MAKE) -C $(EXT)

#
# make misc subdirs
#
subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

$(PPRZCENTER): lib

$(LOGALIZER): lib


static_h: $(GEN_HEADERS)

$(MESSAGES_H) : $(MESSAGES_XML) tools
	$(Q)test -d $(STATICINCLUDE) || mkdir -p $(STATICINCLUDE)
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_messages.out $< telemetry > /tmp/msg.h
	$(Q)mv /tmp/msg.h $@
	$(Q)chmod a+r $@

$(MESSAGES2_H) : $(MESSAGES_XML) tools
	$(Q)test -d $(STATICINCLUDE) || mkdir -p $(STATICINCLUDE)
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_messages2.out $< telemetry > /tmp/msg2.h
	$(Q)mv /tmp/msg2.h $@
	$(Q)chmod a+r $@

$(UBX_PROTOCOL_H) : $(UBX_XML) tools
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_ubx.out $< > /tmp/ubx.h
	$(Q)mv /tmp/ubx.h $@

$(MTK_PROTOCOL_H) : $(MTK_XML) tools
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_mtk.out $< > /tmp/mtk.h
	$(Q)mv /tmp/mtk.h $@

$(XSENS_PROTOCOL_H) : $(XSENS_XML) tools
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_xsens.out $< > /tmp/xsens.h
	$(Q)mv /tmp/xsens.h $@

$(DL_PROTOCOL_H) : $(MESSAGES_XML) tools
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_messages.out $< datalink > /tmp/dl.h
	$(Q)mv /tmp/dl.h $@

$(DL_PROTOCOL2_H) : $(MESSAGES_XML) tools
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_messages2.out $< datalink > /tmp/dl2.h
	$(Q)mv /tmp/dl2.h $@

$(ABI_MESSAGES_H) : $(MESSAGES_XML) tools
	@echo BUILD $@
	$(Q)PAPARAZZI_SRC=$(PAPARAZZI_SRC) PAPARAZZI_HOME=$(PAPARAZZI_HOME) $(TOOLS)/gen_abi.out $< airborne > /tmp/abi.h
	$(Q)mv /tmp/abi.h $@


include Makefile.ac

ac_h ac fbw ap: static conf tools ext

sim: sim_static


#
# Commands
#

# stuff to build and upload the lpc bootloader ...
include Makefile.lpctools
lpctools: lpc21iap usb_lib

commands: paparazzi

paparazzi:
	cat src/paparazzi | sed s#OCAMLRUN#$(OCAMLRUN)# | sed s#OCAML#$(OCAML)# > $@
	chmod a+x $@


install :
	$(MAKE) -f Makefile.install PREFIX=$(PREFIX)

uninstall :
	$(MAKE) -f Makefile.install PREFIX=$(PREFIX) uninstall


#
# Cleaning
#

clean:
	$(Q)rm -fr dox build-stamp configure-stamp conf/%gconf.xml debian/files debian/paparazzi-base debian/paparazzi-bin
	$(Q)rm -f  $(GEN_HEADERS)
	$(Q)find . -mindepth 2 -name Makefile -a ! -path "./sw/ext/*" -exec sh -c 'echo "Cleaning {}"; $(MAKE) -C `dirname {}` $@' \;
	$(Q)$(MAKE) -C $(EXT) clean
	$(Q)find . -name '*~' -exec rm -f {} \;

cleanspaces:
	find sw -path sw/ext -prune -o -name '*.[ch]' -exec sed -i {} -e 's/[ \t]*$$//' \;
	find conf -name '*.makefile' -exec sed -i {} -e 's/[ \t]*$$//' ';'
	find . -path ./sw/ext -prune -o -name Makefile -exec sed -i {} -e 's/[ \t]*$$//' ';'
	find sw -name '*.ml' -o -name '*.mli' -exec sed -i {} -e 's/[ \t]*$$//' ';'
	find conf -name '*.xml' -exec sed -i {} -e 's/[ \t]*$$//' ';'

distclean : dist_clean
dist_clean :
	@echo "Warning: This removes all non-repository files. This means you will loose your aircraft list, your maps, your logfiles, ... if you want this, then run: make dist_clean_irreversible"

dist_clean_irreversible: clean
	rm -rf conf/maps_data conf/maps.xml
	rm -rf conf/conf.xml conf/controlpanel.xml
	rm -rf var

ab_clean:
	find sw/airborne -name '*~' -exec rm -f {} \;


#
# Tests
#

replace_current_conf_xml:
	test conf/conf.xml && mv conf/conf.xml conf/conf.xml.backup.$(BUILD_DATETIME)
	cp conf/tests_conf.xml conf/conf.xml

restore_conf_xml:
	test conf/conf.xml.backup.$(BUILD_DATETIME) && mv conf/conf.xml.backup.$(BUILD_DATETIME) conf/conf.xml

run_tests:
	cd tests; $(MAKE) test

test: all replace_current_conf_xml run_tests restore_conf_xml


.PHONY: all print_build_version update_google_version ground_segment \
subdirs $(SUBDIRS) conf ext lib multimon cockpit tmtc tools\
static sim_static lpctools commands install uninstall \
clean cleanspaces ab_clean dist_clean distclean dist_clean_irreversible \
test replace_current_conf_xml run_tests restore_conf_xml
