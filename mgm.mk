##
# My Great Makefile v0.6.4
#
# Julien Fontanet <julien.fontanet@isonoe.net>
#
# Copyleft 2011
#
# 2011-07-29 - v0.6.4
# - Use  the  same  system  for  warnings  as  the  Linux  Kernel.  Consequently
#   EXTRA_WARNINGS as been removed and replace with WLEVELS.
# - The variable STRICT can be used to turn all warnings into errors.
# - The notion of  project as been replaced with the notion  of targets. All the
#   variables as been renamed accordingly.
# 2011-07-04 - v0.6.3
# - Stupid bug (impossible to use a different BUILD_DIR than “.mgm”) fixed.
# 2011-07-04 - v0.6.2
# - Bug fixes.
# 2011-07-04 - v0.6.1
# - Out-of-tree build!
# - No more error on “distclean” when the directory does not exist.
# 2011-07-03 - v0.6
# - All the code has been rewritten.
# - MGM is now able to compile libraries (easily).
# - Most of the configuration can be made per-project.
# - The default project is now “default”, in lowercase.
# - The “OPENMP” option has been removed, because too specific.
# 2011-03-21 - v0.5.2
# - The extra warnings can be deactivated by setting EXTRA_WARNINGS to 0.
# - Include directories  may be specified with the  global variable INCLUDE_DIRS
#   or with the per-project variable $(project_name)_INCLUDE_DIRS.
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
#     TARGETS := pgm1 pgm2
#     pgm1_SRCS := pgm1.cpp
#     pgm2_NAME := bin/pgm2.exe
#     include mgm.mk
#
# In the previous example, two targets are declared: “pgm1” and “pgm2”.
#
# The source  file for  the first one  is explicited,  it is “pgm1.cpp”  for the
# second one, the default rule is applied,  all the “.c” and “.cpp” files in the
# “pgm2/” directory are used.
#
# The name  for the second target  is explicited, it will  be “bin/pgm2.exe”, to
# the contrary,  for the first  target, the default  rule is used  which specify
# that its name will be “bin/pgm1”.
#
# One  last  thing,  if no  targets  are  declared,  a  default one  is  created
# (“default”), its default  sources are all “.c” and “.cpp”  files in the “src/”
# directory.
##

########################################
# Global configuration

VERBOSE ?= 0
COLORS  ?= 1

MKDIR := mkdir --parents --
RMDIR := rmdir --parents --ignore-fail-on-non-empty --

########################################
# Default configuration for each target

# Which warning levels do you want to use:
#
# 1 - warnings that may be relevant and does not occur too often
# 2 - warnings that occur quite often but may still be relevant
# 3 - the more obscure warnings, can most likely be ignored
#
# You can combine them:
#
#     WLEVELS = 12
WLEVELS ?= 1

# Set this variable to 1 to turn all warnings into errors.
STRICT ?= 0

INCLUDE_DIRS ?=
LINK_DIRS    ?=
LIBRARIES    ?=

# If you  are compiling  a shared  library instead of  an executable,  sets this
# option to 1. All the objects will be compiled using the “-fPIC” option.
IS_LIBRARY ?= 0

DEBUG     ?= 1
PROFILING ?= 0

CFLAGS   ?= -std=c99 -pedantic -Wall
CXXFLAGS ?= -std=c++98 -pedantic -Wall
LDFLAGS  ?=

# The “-MMD” option of GCC/G++  enables the generation of dependency files which
# are  used  to determine  which  file  should  be (re)compiled.   Modify  these
# parameters at your own risk.
CC  := gcc -MMD
CXX := g++ -MMD

# This is the directory in which all the files generated by the compilation will
# be.
BUILD_DIR := .mgm

########################################
# Default directories

# See http://www.gnu.org/software/autoconf/manual/make/Directory-Variables.html
prefix        ?= /usr/local
exec_prefix   ?= $(prefix)
bindir        ?= $(exec_prefix)/bin
sbindir       ?= $(exec_prefix)/sbin
libexecdir    ?= $(exec_prefix)/libexec
datarootdir   ?= $(prefix)/share
datadir       ?= $(datarootdir)
sysconfdir    ?= $(prefix)/etc
localstatedir ?= $(prefix)/var
includedir    ?= $(prefix)/include
oldincludedir ?= $(includedir)
docrootdir    ?= $(datarootdir)/doc # This entry will be suffixed by the target.
infodir       ?= $(datarootdir)/info
libdir        ?= $(exec_prefix)/lib
localedir     ?= $(datarootdir)/local
mandir        ?= $(datarootdir)/man

# The  following  entries  are  not defined:  sharedstatedir,  htmldir,  dvidir,
# pdfdir, psdir, lispdir, man?dir, manext, man?extdir and srcdir.



########################################
########################################
########################################



# If there are no targets defined.
ifeq ($(TARGETS),)
TARGETS      := default
default_SRCS ?= $(shell find src/ -name '*.c' -o -name '*.cpp')
endif

########################################

.DEFAULT_GOAL := all

.PHONY: all clean distclean doc install uninstall

ifneq ($(VERBOSE),1)
.SILENT:
endif

########################################

ifeq ($(COLORS),1)
_COLOR_C := \033[0;1;34m # Blue bold
_COLOR_L := \033[0;1;35m # Purple bold
_COLOR_I := \033[0;1;33m # Yellow bold
_COLOR_U := \033[0;1;33m # Yellow bold
_COLOR_R := \033[0m
endif

########################################
# This comes from the Linux kernel build system.

WARNINGS-1 := extra unused no-unused-parameter
WARNINGS-1 += missing-declarations
WARNINGS-1 += missing-format-attribute
WARNINGS-1 += missing-prototypes
WARNINGS-1 += old-style-definition
WARNINGS-1 += missing-include-dirs
WARNINGS-1 += unused-but-set-variable

WARNINGS-2 := aggregate-return
WARNINGS-2 += cast-align
WARNINGS-2 += disabled-optimization
WARNINGS-2 += nested-externs
WARNINGS-2 += shadow
WARNINGS-2 += logical-op

WARNINGS-3 := bad-function-cast
WARNINGS-3 += cast-qual
WARNINGS-3 += conversion
WARNINGS-3 += packed
WARNINGS-3 += padded
WARNINGS-3 += pointer-arith
WARNINGS-3 += redundant-decls
WARNINGS-3 += switch-default
WARNINGS-3 += packed-bitfield-compat
WARNINGS-3 += vla

# CFLAGS += $(call GET_WARNINGS,$(WLEVELS))
GET_WARNINGS = $(patsubst %,-W%,\
                          $(WARNINGS-$(findstring 1, $(1)))\
                          $(WARNINGS-$(findstring 2, $(1)))\
                          $(WARNINGS-$(findstring 3, $(1))))

########################################

TARGET_SPECIFIC_VARS  :=   WLEVELS  STRICT  INCLUDE_DIRS   LINK_DIRS  LIBRARIES	\
                        IS_LIBRARY DEBUG  PROFILING CFLAGS CXXFLAGS  LDFLAGS CC	\
                        CXX   BUILD_DIR  prefix   exec_prefix   bindir  sbindir	\
                        libexecdir datarootdir datadir sysconfdir localstatedir	\
                        includedir  oldincludedir   docrootdir  infodir  libdir	\
                        localedir mandir

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

# $(call ADD_OBJECT,OBJS_LIST,SOURCE,OBJECT)
define ADD_OBJECT
override $(1) := $$($(1)) $(3)
$(3): override SRC := $(2)
endef

########################################

# $(call TARGET_TPL,TARGET_NAME)
define TARGET_TPL

# Defines the  target-specific variables with the  default ones if  they are not
# already set.
$$(foreach var,\
           $(TARGET_SPECIFIC_VARS),\
           $$(eval $$(call INHERIT_VAR,$$(var),$(1))))

# Filters this options to simplify conditional treatments (1 or empty).
$$(foreach var,\
           STRICT IS_LIBRARY DEBUG PROFILING,\
           $$(eval $$(call SANITIZE_OPTION,$(1)_$$(var))))

# This is where the documentation will be saved.
$(1)_docdir ?= $$($(1)_docrootdir)/$(1)

# Where   should  the  file   be  compiled?   (default  is   bin/TARGET_NAME  or
# bin/libTARGET_NAME.so)
$(1)_NAME ?= bin/$$(if $$($(1)_IS_LIBRARY),lib$(1).so,$(1))

# What  are  the  source  files  of  this  target?  (default  is  all  files  in
# TARGET_NAME/)
$(1)_SRCS ?= $$(shell find $(1)/ -name '*.c' -o -name '*.cpp')

# Where to install the target?
$(1)_INSTALL ?= $$(if $$($(1)_IS_LIBRARY),$$($(1)_libdir),$$($(1)_bindir))/$$(notdir $$($(1)_NAME))

# Files used for the compilation.
$$(foreach src,\
           $$($(1)_SRCS),\
           $$(eval $$(call ADD_OBJECT,_$(1)_OBJS,$$(src),$$($(1)_BUILD_DIR)/$$(src:%=%.o))))
_$(1)_DEPS := $$(_$(1)_OBJS:%.o=%.d)

# Builds options list from certain variables.
_$(1)_INCLUDE_DIRS := $$($(1)_INCLUDE_DIRS:%=-I%)
_$(1)_LINK_DIRS    := $$($(1)_LINK_DIRS:%=-L%)
_$(1)_LIBRARIES    := $$($(1)_LIBRARIES:%=-l%)

# Additional conditional flags.
_tmp := $$(if $$($(1)_IS_LIBRARY),-fPIC)\
        $$(if $$($(1)_DEBUG),-ggdb3,-DNDEBUG -fno-strict-aliasing -funroll-loops -O3 -g0)\
        $$(if $$($(1)_PROFILING),-pg)\
        $$(call GET_WARNINGS,$$($(1)_WLEVELS))\
        $$(if $$($(1)_STRICT),-Werror)
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

all: $$($(1)_NAME)
$$($(1)_NAME): $$(_$(1)_OBJS)
	$(MKDIR) $$(dir $$($(1)_NAME))
	@printf '  $(_COLOR_L)L  %s$(_COLOR_R)\n' $$($(1)_NAME)
	$$($(1)_CXX) $$($(1)_LDFLAGS) \
                 $$(_$(1)_LINK_DIRS) $$(_$(1)_LIBRARIES) \
                 -o $$($(1)_NAME) $$^

clean: clean-$(1)
clean-$(1): _DIRS := $$(wildcard $$(sort $$(dir $$(_$(1)_OBJS))))
clean-$(1):
	$(RM) -v $$(_$(1)_DEPS) $$(_$(1)_OBJS)
	$$(if $$(_DIRS),$(RMDIR) $$(_DIRS))

distclean: distclean-$(1)
distclean-$(1): _DIR := $$(wildcard $$(dir $$($(1)_NAME)))
distclean-$(1): clean-$(1)
	$(RM) -v $$($(1)_NAME)
	$$(if $$(_DIR),$(RMDIR) $$(_DIR))

install: install-$(1)
install-$(1): $$($(1)_INSTALL)
$$($(1)_INSTALL): $$($(1)_NAME)
	@printf '  $(_COLOR_I)I  %s$(_COLOR_R)\n' $$($(1)_INSTALL)
	$(MKDIR) $$(dir $$($(1)_INSTALL))
	cp -f $$^ $$($(1)_INSTALL)

uninstall: $$(if $$(wildcard $$($(1)_INSTALL)),uninstall-$(1))
uninstall-$(1): _DIR := $$(wildcard $$(dir $$($(1)_INSTALL)))
uninstall-$(1):
	@printf '  $(_COLOR_U)U  %s$(_COLOR_R)\n' $$($(1)_INSTALL)
	$(RM) -v $$($(1)_INSTALL)
	$$(if $$(_DIR),$(RMDIR) $$(_DIR))

#doc: doc-$(1)

endef

########################################

# Creates rules for each target.
$(foreach target,$(TARGETS),$(eval $(call TARGET_TPL,$(target))))

########################################

.SUFFIXES: # Disable auto rules

%.c.o:
	$(MKDIR) $(dir $@)
	@printf '  $(_COLOR_C)CC %s$(_COLOR_R)\n' $(SRC)
	$(CC) $(CFLAGS) -c -o $@ $(SRC)

%.cpp.o:
	$(MKDIR) $(dir $@)
	@printf '  $(_COLOR_C)CC %s$(_COLOR_R)\n' $(SRC)
	$(CXX) $(CXXFLAGS) -c -o $@ $(SRC)
