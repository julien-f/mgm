##
# My Great Makefile v0.6
#
# Julien Fontanet <julien.fontanet@isonoe.net>
#
# Copyleft 2011
#
# 2011-07-03 - v0.6
# - All the code has been rewritten.
# - MGM is now able to compile libraries (easily).
# - Most of the configuration can be made per-project.
# - The default project is now “default”, in lowercase.
# - The “OPENMP” option has been removed, because too specific.
# 2011-03-21 - v0.5.2
# - The extra warnings can be deactivated by setting EXTRA_WARNINGS to 0.
# - Include directories  may be specified with the  global variable INCLUDE_DIRS
#  or with the per-project variable $(project_name)_INCLUDE_DIRS.
##

##
# This Makefile works only with GNU make and gcc/g++ (g++ is used for linking).
# The C suffix is ".c".
# The C++ suffix is ".cpp".
#
# This file is  aimed to be included in a Makefile  after some configuration has
# been done through variables.
#
#
# Example
# -------
#
#     PROJECTS := pgm1 pgm2
#     pgm1_SRCS := pgm1.cpp
#     pgm2_TARGET := bin/pgm2.exe
#     include mgm.mk
#
# In the previous example, two projects are declared: “pgm1” and “pgm2”.
#
# The source  file for  the first one  is explicited,  it is “pgm1.cpp”  for the
# second one, the default rule is applied,  all the “.c” and “.cpp” files in the
# “pgm2/” directory are used.
#
# The target for the second project is explicited, it will be “bin/pgm2.exe”, to
# the contrary,  for the first project,  the default rule is  used which specify
# that its target will be “bin/pgm1”.
#
# One  last  thing, if  no  projects  are declared,  a  default  one is  created
# (“default”), its default  sources are all “.c” and “.cpp”  files in the “src/”
# directory.
##

########################################
# Global configuration

VERBOSE        ?= 0
COLORS         ?= 1

########################################
# Default configuration for each project

INCLUDE_DIRS ?=
LINK_DIRS    ?=
LIBRARIES    ?=

# If you  are compiling  a shared  library instead of  an executable,  sets this
# option to 1. All the objects will be compiled using the “-fPIC” option.
IS_LIBRARY ?= 0

DEBUG          ?= 1
PROFILING      ?= 0
EXTRA_WARNINGS ?= 1

CFLAGS   ?= -std=c99 -pedantic -Wall
CXXFLAGS ?= -std=c++98 -pedantic -Wall
LDFLAGS  ?=

# The “-MMD” option of GCC/G++  enables the generation of dependency files which
# are  used  to  determine  which  file should  be  (re)compiled.  Modify  these
# parameters at your own risk.
CC  := gcc -MMD
CXX := g++ -MMD

########################################
# Default directories

# See http://www.gnu.org/software/autoconf/manual/make/Directory-Variables.html
prefix         ?= /usr/local
exec_prefix    ?= $(prefix)
bindir         ?= $(exec_prefix)/bin
sbindir        ?= $(exec_prefix)/sbin
libexecdir     ?= $(exec_prefix)/libexec
datarootdir    ?= $(prefix)/share
datadir        ?= $(datarootdir)
sysconfdir     ?= $(prefix)/etc
localstatedir  ?= $(prefix)/var
includedir     ?= $(prefix)/include
oldincludedir  ?= $(includedir)
docrootdir     ?= $(datarootdir)/doc # This entry will be suffixed by the project name.
infodir        ?= $(datarootdir)/info
libdir         ?= $(exec_prefix)/lib
localedir      ?= $(datarootdir)/local
mandir         ?= $(datarootdir)/man

# The  following  entries  are  not defined:  sharedstatedir,  htmldir,  dvidir,
# pdfdir, psdir, lispdir, man?dir, manext, man?extdir and srcdir.



########################################
########################################
########################################



# If there are no projects defined.
ifeq ($(PROJECTS),)
PROJECTS       := default
default_SRCS   ?= $(shell find src/ -name '*.c' -o -name '*.cpp')
endif

########################################

.DEFAULT_GOAL := all
.PHONY: all clean distclean doc install uninstall

ifneq ($(VERBOSE),1)
.SILENT:
endif

ifeq ($(COLORS),1)
_COLOR_C := \033[0;1;34m # Blue bold
_COLOR_L := \033[0;1;35m # Purple bold
_COLOR_I := \033[0;1;33m # Yellow bold
_COLOR_U := \033[0;1;33m # Yellow bold
_COLOR_R := \033[0m
endif

########################################

PROJECT_SPECIFIC_VARS  :=  INCLUDE_DIRS  LINK_DIRS  LIBRARIES  IS_LIBRARY  DEBUG	\
                         PROFILING EXTRA_WARNINGS CFLAGS CXXFLAGS LDFLAGS CC CXX	\
                         prefix    exec_prefix    bindir   sbindir    libexecdir	\
                         datarootdir datadir sysconfdir localstatedir includedir	\
                         oldincludedir   docrootdir  infodir   libdir  localedir	\
                         mandir

# $(call INHERIT_VAR,VAR_NAME,PREFIX)
define INHERIT_VAR
$(2)_$(1) ?= $$($(1))
endef

########################################

# $(call SANITIZE_OPTION,OPTION_NAME)
define SANITIZE_OPTION
override $(1) := $$(findstring 1,$$($(1)))
endef

########################################

# $(call PROJECT_TPL,PROJECT_NAME)
define PROJECT_TPL

# Defines the project-specific  variables with the default ones  if they are not
# already set.
$$(foreach var,\
           $(PROJECT_SPECIFIC_VARS),\
           $$(eval $$(call INHERIT_VAR,$$(var),$(1))))

# Filters this options to simplify conditional treatments (1 or empty).
$$(foreach var,\
           IS_LIBRARY DEBUG PROFILING EXTRA_WARNINGS,\
           $$(eval $$(call SANITIZE_OPTION,$(1)_$$(var))))

# This is where the documentation will be saved.
$(1)_docdir ?= $$($(1)_docrootdir)/$(1)

# Where should the file be compiled? (default is bin/PROJECT_NAME or bin/libPROJECT_NAME.so)
$(1)_TARGET ?= bin/$$(if $$($(1)_IS_LIBRARY),lib$(1).so,$(1))

# What are the source files of this project? (default is all files in PROJECT_NAME/)
$(1)_SRCS ?= $$(shell find $(1)/ -name '*.c' -o -name '*.cpp')

# Where to install the target?
$(1)_INSTALL ?= $$(if $$($(1)_IS_LIBRARY),$$($(1)_libdir),$$($(1)_bindir))/$$(notdir $$($(1)_TARGET))

# Files used for the compilation.
_$(1)_OBJS := $$($(1)_SRCS:%=%.o)
_$(1)_DEPS := $$($(1)_SRCS:%=%.d)

# Builds options list from certain variables.
_$(1)_INCLUDE_DIRS := $$($(1)_INCLUDE_DIRS:%=-I%)
_$(1)_LINK_DIRS    := $$($(1)_LINK_DIRS:%=-L%)
_$(1)_LIBRARIES    := $$($(1)_LIBRARIES:%=-l%)

# Additional conditional flags.
_tmp := $$(if $$($(1)_IS_LIBRARY),-fPIC)\
        $$(if $$($(1)_DEBUG),-ggdb3,-DNDEBUG -fno-strict-aliasing -funroll-loops -O3 -g0)\
        $$(if $$($(1)_PROFILING),-pg)\
        $$(if $$($(1)_EXTRA_WARNINGS),-Wextra -Wconversion -Winline)
override $(1)_CFLAGS   := $$($(1)_CFLAGS) $$(_tmp)
override $(1)_CXXFLAGS := $$($(1)_CXXFLAGS) $$(_tmp)

_tmp := -shared -Wl,-soname,$(1)
override $(1)_LDFLAGS := $$($(1)_LDFLAGS)\
                         $$(if $$($(1)_IS_LIBRARY),$$(_tmp))\
                         $$(if $$($(1)_PROFILING),-pg)

# Parameters to build the objects.
$$(_$(1)_OBJS): override CC  := $$($(1)_CC)
$$(_$(1)_OBJS): override CXX := $$($(1)_CXX)
$$(_$(1)_OBJS): override CFLAGS   := $$($(1)_CFLAGS) $$(_$(1)_INCLUDE_DIRS)
$$(_$(1)_OBJS): override CXXFLAGS := $$($(1)_CXXFLAGS) $$(_$(1)_INCLUDE_DIRS)
$$(_$(1)_OBJS): $(MAKEFILE_LIST)

# Includes the dependencies files.
-include $$(_$(1)_DEPS)

.PHONY: clean-$(1) distclean-$(1) doc-$(1) install-$(1) uninstall-$(1)

all: $$($(1)_TARGET)
$$($(1)_TARGET): $$(_$(1)_OBJS)
	mkdir -p -- $$(dir $$($(1)_TARGET))
	@printf '  $(_COLOR_L)L  %s$(_COLOR_R)\n' $$($(1)_TARGET)
	$$($(1)_CXX) $$($(1)_LDFLAGS) \
                 $$(_$(1)_LINK_DIRS) $$(_$(1)_LIBRARIES) \
                 -o $$($(1)_TARGET) $$^

clean: clean-$(1)
clean-$(1):
	$(RM) -v $$(_$(1)_DEPS) $$(_$(1)_OBJS)

distclean: distclean-$(1)
distclean-$(1): clean-$(1)
	$(RM) -v $$($(1)_TARGET)
	rmdir --parents --ignore-fail-on-non-empty -- $$(dir $$($(1)_TARGET))

install: install-$(1)
install-$(1): $$($(1)_INSTALL)
$$($(1)_INSTALL): $$($(1)_TARGET)
	@printf '  $(_COLOR_I)I  %s$(_COLOR_R)\n' $$($(1)_INSTALL)
	mkdir -p -- $$(dir $$($(1)_INSTALL))
	cp -f $$^ $$($(1)_INSTALL)

uninstall: $$(if $$(wildcard $$($(1)_INSTALL)),uninstall-$(1))
uninstall-$(1):
	@printf '  $(_COLOR_U)U  %s$(_COLOR_R)\n' $$($(1)_INSTALL)
	$(RM) -v $$($(1)_INSTALL)

#doc: doc-$(1)

endef

########################################

# Creates rules for each project.
$(foreach project,$(PROJECTS),$(eval $(call PROJECT_TPL,$(project))))

########################################

.SUFFIXES: # Disable auto rules

%.c.o: %.c
	@printf '  $(_COLOR_C)CC %s$(_COLOR_R)\n' $@
	$(CC) $(CFLAGS) -c -o $@ $<

%.cpp.o: %.cpp
	@printf '  $(_COLOR_C)CC %s$(_COLOR_R)\n' $@
	$(CXX) $(CXXFLAGS) -c -o $@ $<
