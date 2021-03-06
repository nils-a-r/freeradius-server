#
# Version:	$Id$
#
HEADERS	= \
	attributes.h \
	build.h \
	conf.h \
	conffile.h \
	detail.h \
	event.h \
	features.h \
	hash.h \
	heap.h \
	libradius.h \
	md4.h \
	md5.h \
	missing.h \
	modcall.h \
	modules.h \
	packet.h \
	rad_assert.h \
	radius.h \
	radiusd.h \
	radutmp.h \
	realms.h \
	sha1.h \
	stats.h \
	sysutmp.h \
	token.h \
	udpfromto.h \
	base64.h \
	map.h

#
#  Build dynamic headers by substituting various values from autoconf.h, these
#  get installed with the library files, so external programs can tell what
#  the server library was built with.
#
HEADERS_DY = src/include/features.h src/include/missing.h src/include/tls.h \
	src/include/radpaths.h src/include/attributes.h

#
#  Solaris awk doesn't recognise [[:blank:]] hence [\t ]
#
src/include/autoconf.sed: src/include/autoconf.h
	@grep ^#define $< | sed 's,/\*\*/,1,;' | awk '{print "'\
	's,#[\\t ]*ifdef[\\t ]*" $$2 "$$,#if "$$3 ",g;'\
	's,#[\\t ]*ifndef[\\t ]*" $$2 "$$,#if !"$$3 ",g;'\
	's,defined(" $$2 ")," $$3 ",g;"}' > $@
	@grep -o '#undef [^ ]*' $< | sed 's,/#undef /,,;' | awk '{print "'\
	's,#[\\t ]*ifdef[\\t ]*" $$2 "$$,#if 0,g;'\
	's,#[\\t ]*ifndef[\\t ]*" $$2 "$$,#if 1,g;'\
	's,defined(" $$2 "),0,g;"}' >> $@


######################################################################
#
#  Create the header files from the dictionaries.
#

RFC_DICTS := $(filter-out %~,$(wildcard share/dictionary.rfc*))
RFC_HEADERS := $(patsubst share/dictionary.%,src/include/%.h,$(RFC_DICTS))

src/include/attributes.h: share/dictionary.freeradius.internal
	@$(ECHO) HEADER $@
	@grep ^ATTRIBUTE $<  | awk '{print "PW_"$$2 " " $$3}' | tr '[:lower:]' '[:upper:]' | tr -- - _ | sed 's/^/#define /' > $@

src/include/%.h: share/dictionary.%
	@$(ECHO) HEADER $@
	@grep ^ATTRIBUTE $<  | awk '{print "PW_"$$2 " " $$3}' | tr '[:lower:]' '[:upper:]' | tr -- - _ | sed 's/^/#define /' > $@

src/include/radius.h: | src/include/attributes.h $(RFC_HEADERS)

#
#  So the headers are created before we compile anything
#
$(JLIBTOOL): src/include/radius.h

src/freeradius-devel/features.h: src/include/features.h src/freeradius-devel

#
#  Build features.h by copying over WITH_* and RADIUSD_VERSION_*
#  preprocessor macros from autoconf.h
#  This means we don't need to include autoconf.h in installed headers.
#
#  We use simple patterns here to work with the lowest common
#  denominator's grep (Solaris).
#
src/include/features.h: src/include/features-h src/include/autoconf.h
	@$(ECHO) HEADER $@
	@cp $< $@
	@grep "^#define[ ]*WITH_" src/include/autoconf.h >> $@
	@grep "^#define[ ]*RADIUSD_VERSION" src/include/autoconf.h >> $@

src/freeradius-devel/missing.h: src/include/missing.h src/freeradius-devel

#
#  Use the SED script we built earlier to make permanent substitutions
#  of definitions in missing-h to build missing.h
#
src/include/missing.h: src/include/missing-h src/include/autoconf.sed
	@$(ECHO) HEADER $@
	@sed -f src/include/autoconf.sed < $< > $@

src/freeradius-devel/tls.h: src/include/tls.h src/freeradius-devel

src/include/tls.h: src/include/tls-h src/include/autoconf.sed
	@$(ECHO) HEADER $@
	@sed -f src/include/autoconf.sed < $< > $@

src/freeradius-devel/radpaths.h: src/include/radpaths.h src/freeradius-devel

src/include/radpaths.h: src/include/build-radpaths-h
	@$(ECHO) HEADER $@
	@cd src/include && /bin/sh build-radpaths-h

${BUILD_DIR}/make/jlibtool: $(HEADERS_DY)

######################################################################
#
#  Installation
#
# define the installation directory
SRC_INCLUDE_DIR := ${R}${includedir}/freeradius

$(SRC_INCLUDE_DIR):
	@$(INSTALL) -d -m 755 ${SRC_INCLUDE_DIR}

#
#  install the headers by re-writing the local files
#
#  install-sh function for creating directories gets confused
#  if there's a trailing slash, tries to create a directory
#  it already created, and fails...
#
${SRC_INCLUDE_DIR}/%.h: ${top_srcdir}/src/include/%.h | $(SRC_INCLUDE_DIR)
	@echo INSTALL $(notdir $<)
	@$(INSTALL) -d -m 755 `echo $(dir $@) | sed 's/\/$$//'`
	@sed 's/^#include <freeradius-devel/#include <freeradius/' < $< > $@
	@chmod 644 $@

install.src.include: $(addprefix ${SRC_INCLUDE_DIR}/,${HEADERS})
install: install.src.include

#
#  Cleaning
#
.PHONY: clean.src.include distclean.src.include
clean.src.include:
	@rm -f $(HEADERS_DY)

clean: clean.src.include

distclean.src.include: clean.src.include
	@rm -f autoconf.sed

distclean: distclean.src.include
