################################################################################
# Makefile for Motion                                                          #
################################################################################
# Copyright 2000 by Jeroen Vreeken                                             #
#                                                                              #
# This program is published under the GNU public license version 2.0 or later. #
# Please read the file COPYING for more info.                                  #
################################################################################
# Please visit the Motion home page:                                           #
# http://www.lavrsen.dk/twiki/bin/view/Motion                                  #
################################################################################

CC      = gcc
INSTALL = install

################################################################################
# Install locations, controlled by setting configure flags.                    #
################################################################################
prefix      = /
exec_prefix = ${prefix}
bindir      = ${exec_prefix}/bin
mandir      = ${datarootdir}/man
sysconfdir  = /etc/motion
datadir     = ${datarootdir}
datarootdir = ${prefix}/share
docdir      = $(datadir)/doc/motion-Git-8619d7c17ce112e7196975905c6e840f345141ba 
examplesdir = $(datadir)/motion-Git-8619d7c17ce112e7196975905c6e840f345141ba/examples

################################################################################
# These variables contain compiler flags, object files to build and files to   #
# install.                                                                     #
################################################################################
CFLAGS       =  -g -O2 -D_REENTRANT -I/usr/include/mysql -DMOTION_V4L2 -DTYPE_32BIT="int" -DHAVE_BSWAP   -march=native -mtune=native -Wall -DVERSION=\"Git-8619d7c17ce112e7196975905c6e840f345141ba\" -Dsysconfdir=\"$(sysconfdir)\" 
LDFLAGS      =  
LIBS         = -lm  -lpthread -ljpeg -L/usr/lib/x86_64-linux-gnu -lmysqlclient -lz 
VIDEO_OBJ    = video.o video2.o video_common.o
OBJ          = motion.o logger.o conf.o draw.o jpegutils.o vloopback_motion.o $(VIDEO_OBJ) \
			   netcam.o netcam_ftp.o netcam_jpeg.o netcam_wget.o track.o \
			   alg.o event.o picture.o rotate.o webhttpd.o \
			   stream.o md5.o  
SRC          = $(OBJ:.o=.c)
DOC          = CHANGELOG COPYING CREDITS INSTALL README motion_guide.html
EXAMPLES     = *.conf motion.init-Debian motion.init-Fedora motion.init-FreeBSD.sh
PROGS        = motion
DEPEND_FILE  = .depend

################################################################################
# ALL and PROGS build Motion and, possibly, Motion-control.                    #
################################################################################
all: progs
ifneq (,$(findstring freebsd,$(VIDEO_OBJ)))
	@echo "Build complete, run \"gmake install\" to install Motion!"
else
	@echo "Build complete, run \"make install\" to install Motion!"
endif
	@echo

progs: pre-build-info $(PROGS)

################################################################################
# PRE-BUILD-INFO outputs some general info before the build process starts.    #
################################################################################
pre-build-info: 
	@echo "Welcome to the setup procedure for Motion, the motion detection daemon! If you get"
	@echo "error messages during this procedure, please report them to the mailing list. The"
	@echo "Motion Guide contains all information you should need to get Motion up and running."
	@echo "Run \"make updateguide\" to download the latest version of the Motion Guide."
	@echo
	@echo "Version: Git-8619d7c17ce112e7196975905c6e840f345141ba"
ifneq (,$(findstring freebsd,$(VIDEO_OBJ)))
	@echo "Platform: FreeBSD"
else
	@echo "Platform: Linux (if this is incorrect, please read README.FreeBSD)"
endif
	@echo

################################################################################
# MOTION builds motion. MOTION-OBJECTS and PRE-MOBJECT-INFO are helpers.       #
################################################################################
motion: motion-objects
	@echo "Linking Motion..."
	@echo "--------------------------------------------------------------------------------"
	$(CC) $(LDFLAGS) -o $@ $(OBJ) $(LIBS)
	@echo "--------------------------------------------------------------------------------"
	@echo "Motion has been linked."
	@echo

motion-objects: dep pre-mobject-info $(OBJ)
	@echo "--------------------------------------------------------------------------------"
	@echo "Motion object files compiled."
	@echo
	
pre-mobject-info:
	@echo "Compiling Motion object files..."
	@echo "--------------------------------------------------------------------------------"

################################################################################
# Define the compile command for C files.                                      #
################################################################################
#%.o: %.c
#	@echo -e "\tCompiling $< into $@..."
#	@$(CC) -c $(CFLAGS) $< -o $@

################################################################################
# Include the dependency file if it exists.                                    #
################################################################################
ifeq ($(DEPEND_FILE), $(wildcard $(DEPEND_FILE)))
ifeq (,$(findstring clean,$(MAKECMDGOALS)))
-include $(DEPEND_FILE)
endif
endif

################################################################################
# Make the dependency file depend on all header files and all relevant source  #
# files. This forces the file to be re-generated if the source/header files    #
# change. Note, however, that the existing version will be included before     #
# re-generation.                                                               #
################################################################################
$(DEPEND_FILE): *.h $(SRC)
	@echo "Generating dependencies, please wait..."
	@$(CC) $(CFLAGS) -M $(SRC) > .tmp
	@mv -f .tmp $(DEPEND_FILE)
	@echo

################################################################################
# DEP, DEPEND and FASTDEP generate the dependency file.                        #
################################################################################
dep depend fastdep: $(DEPEND_FILE)


################################################################################
# DEV, BUILD with developer flags                                              #
################################################################################
dev: distclean autotools all

################################################################################
# DEV-GIT, BUILD with developer flags                                          #
################################################################################
dev-git: distclean autotools-git all


################################################################################
# GIT, BUILD with developer flags                                              #
################################################################################
build-commit-git: distclean set-version-git all

################################################################################
# CURRENT, BUILD current svn trunk.                                            #
################################################################################
current: distclean svn autotools all

svn:
	svn update

autotools:
	@sed -i 's/.\/commit-version.sh/.\/version.sh/g' configure.in
	autoconf
	./configure --with-developer-flags 

autotools-git:
	@sed -i 's/.\/git-commit-version.sh/.\/version.sh/g' configure.in
	autoconf
	./configure --with-developer-flags 


build-commit: distclean svn set-version all

set-version:
	@sed -i 's/.\/version.sh/.\/commit-version.sh/g' configure.in
	autoconf
	@sed -i 's/.\/commit-version.sh/.\/version.sh/g' configure.in
	./configure --with-developer-flags

set-version-git:
	@sed -i 's/.\/version.sh/.\/git-commit-version.sh/g' configure.in
	autoconf
	@sed -i 's/.\/git-commit-version.sh/.\/version.sh/g' configure.in
	./configure --with-developer-flags


help:
	@echo "--------------------------------------------------------------------------------"
	@echo "make                   Build motion from local copy in your computer"	
	@echo "make current           Build last version of motion from svn"
	@echo "make dev               Build motion with dev flags"
	@echo "make dev-git           Build motion with dev flags for git"
	@echo "make build-commit      Build last version of motion and prepare to commit to svn"
	@echo "make build-commit-git  Build last version of motion and prepare to commit to git"
	@echo "make clean             Clean objects" 
	@echo "make distclean         Clean everything"	
	@echo "make install           Install binary , examples , docs and config files"
	@echo "make uninstall         Uninstall all installed files"
	@echo "--------------------------------------------------------------------------------"
	@echo

################################################################################
# INSTALL installs all relevant files.                                         #
################################################################################
install:
	@echo "Installing files..."
	@echo "--------------------------------------------------------------------------------"
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(mandir)/man1
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(docdir)
	mkdir -p $(DESTDIR)$(examplesdir)
	$(INSTALL) motion.1 $(DESTDIR)$(mandir)/man1
	$(INSTALL) $(DOC) $(DESTDIR)$(docdir)
	$(INSTALL) $(EXAMPLES) $(DESTDIR)$(examplesdir)
	$(INSTALL) motion-dist.conf $(DESTDIR)$(sysconfdir)
	for prog in $(PROGS); \
	do \
	($(INSTALL) $$prog $(DESTDIR)$(bindir) ); \
	done
	@echo "--------------------------------------------------------------------------------"
	@echo "Install complete! The default configuration file, motion-dist.conf, has been"
	@echo "installed to $(sysconfdir). You need to rename/copy it to $(sysconfdir)/motion.conf"
	@echo "for Motion to find it. More configuration examples as well as init scripts"
	@echo "can be found in $(examplesdir)."
	@echo

################################################################################
# UNINSTALL and REMOVE uninstall already installed files.                      #
################################################################################
uninstall remove: pre-build-info
	@echo "Uninstalling files..."
	@echo "--------------------------------------------------------------------------------"
	for prog in $(PROGS); \
	do \
		($ rm -f $(bindir)/$$prog ); \
	done
	rm -f $(mandir)/man1/motion.1
	rm -f $(sysconfdir)/motion-dist.conf
	rm -rf $(docdir)
	rm -rf $(examplesdir)
	@echo "--------------------------------------------------------------------------------"
	@echo "Uninstall complete!"
	@echo

################################################################################
# CLEAN is basic cleaning; removes object files and executables, but does not  #
# remove files generated from the configure step.                              #
################################################################################
clean: pre-build-info
	@echo "Removing compiled files and binaries..."
	@rm -f *~ *.jpg *.o $(PROGS) combine $(DEPEND_FILE)

################################################################################
# DIST restores the directory to distribution state.                           #
################################################################################
dist: distclean updateguide
	@chmod -R 644 *
	@chmod 755 configure
	@chmod 755 version.sh

################################################################################
# DISTCLEAN removes all files generated during the configure step in addition  #
# to basic cleaning.                                                           #
################################################################################
distclean: clean
	@echo "Removing files generated by configure..."
	@rm -f config.status config.log config.cache Makefile motion.init-Fedora motion.init-Debian motion.init-FreeBSD.sh
	@rm -f thread1.conf thread2.conf thread3.conf thread4.conf motion-dist.conf motion-help.conf motion.spec
	@rm -rf autom4te.cache config.h
	@echo "You will need to re-run configure if you want to build Motion."
	@echo

################################################################################
# UPDATEGUIDE downloads the Motion Guide from TWiki.                           #
################################################################################
updateguide: pre-build-info
	@echo "Downloading Motion Guide. If it fails, please check your Internet connection."
	@echo
	wget www.lavrsen.dk/twiki/bin/view/Motion/MotionGuideOneLargeDocument?skin=text -O motion_guide.tmp
	@echo "Cleaning up and fixing links..."
	@cat motion_guide.tmp | sed -e 's/\?skin=text//g;s,"/twiki/,"http://www.lavrsen.dk/twiki/,g' > motion_guide.html
	@rm -f motion_guide.tmp
	@echo "All done, you should now have an up-to-date local copy of the Motion guide."
	@echo
