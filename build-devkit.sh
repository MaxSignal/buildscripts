#!/bin/bash
#---------------------------------------------------------------------------------
# Build scripts for
#	devkitARM release 40
#	devkitPPC release 26
#	devkitPSP release 17
#	devkitSH4 release 1
#---------------------------------------------------------------------------------

if [ 0 -eq 1 ] ; then
	echo "Currently in release cycle, proceed with caution, do not report problems, do not ask for support."
	echo "Please use the latest release buildscripts unless advised otherwise by devkitPro staff."
	echo "http://sourceforge.net/projects/devkitpro/files/buildscripts/"
	echo
	echo "The scripts in svn are quite often dependent on things which currently only exist on developer"
	echo "machines. This is not a bug, use stable releases."
	exit 1
fi

echo "Please note, these scripts are provided as a courtesy, toolchains built with them"
echo "are for personal use only and may not be distributed by entities other than devkitPro."
echo "See http://devkitpro.org/wiki/Trademarks"
echo
echo "Patches and improvements are of course welcome, please send these to the patch tracker"
echo "https://sourceforge.net/tracker/?group_id=114505&atid=668553"
echo

LIBOGC_VER=1.8.11
LIBGBA_VER=20090222
LIBNDS_VER=1.5.7
DEFAULT_ARM7_VER=0.5.24
DSWIFI_VER=0.3.13
LIBMIRKO_VER=0.9.7
MAXMOD_VER=1.0.7
FILESYSTEM_VER=0.9.9
LIBFAT_VER=1.0.11
LIBDATAPLUS_VER=master
PSPSDK_VER=20120404
GBATOOLS_VER=1.0.0
GRIT_VER=0.8.10
NDSTOOL_VER=1.50.1
GENERAL_TOOLS_VER=1.0.0
DLDITOOL_VER=1.24.0
GXTEXCONV_VER=0.1.9
GCDSPSUITE_VER=1.4.0
ELF2DOL_VER=1.0.0
WIILOAD_VER=0.5.1
MMUTIL_VER=1.8.6
ELF2D01_VER=1.0.0
DFU_UTIL_VER=0.6
STLINK_VER=0.5.3

#---------------------------------------------------------------------------------
function git_clone_project {
#---------------------------------------------------------------------------------
	name=$(echo $1 | sed -e 's/.*\/\([^/]*\)\.git/\1/' )
	if [ ! -f cloned-$name ]; then
		echo "cloning $name"
		git clone $1 -b $2 $name-$2 || { echo "Error cloning $name"; exit 1; }
		touch cloned-$name
	fi
}

#---------------------------------------------------------------------------------
function extract_and_patch {
#---------------------------------------------------------------------------------
	if [ ! -f extracted-$1 ]; then
		echo "extracting $1"
		if [ $3 == "bz2" ]; then
			extractflags="-xjf"
			archivetype=".tar.bz2"
		elif [ $3 == "gz" ]; then
			extractflags="-xzf"
			archivetype=".tar.gz"
		else
			echo "invalid archive type"
			exit 1
		fi
		tar $extractflags $SRCDIR/$1-$2$archivetype || { echo "Error extracting $1"; exit 1; }
		touch extracted-$1
	fi
	if [[ ! -f patched-$1 && -f $patchdir/$1-$2.patch ]]; then
		echo "patching $1"
		patch -p1 -d $1-$2 -i $patchdir/$1-$2.patch || { echo "Error patching $1"; exit 1; }
		touch patched-$1
	fi
}

if [ ! -z "$CROSSBUILD" ] ; then
	if [ ! -x $(which $CROSSBUILD-gcc) ]; then
		echo "error $CROSSBUILD-gcc not in PATH"
		exit 1
	fi
fi

#---------------------------------------------------------------------------------
# Sane defaults for building toolchain
#---------------------------------------------------------------------------------
export CFLAGS="-O2 -pipe"
export CXXFLAGS="$CFLAGS"
unset LDFLAGS

#---------------------------------------------------------------------------------
# Look for automated configuration file to bypass prompts
#---------------------------------------------------------------------------------
 
echo -n "Looking for configuration file... "
if [ -f ./config.sh ]; then
  echo "Found."
  . ./config.sh
else
  echo "Not found"
fi
. ./select_toolchain.sh

#---------------------------------------------------------------------------------
# Get preferred installation directory and set paths to the sources
#---------------------------------------------------------------------------------

if [ ! -z "$BUILD_DKPRO_INSTALLDIR" ] ; then
	INSTALLDIR="$BUILD_DKPRO_INSTALLDIR"
else
	echo
	echo "Please enter the directory where you would like '$package' to be installed:"
	echo "for mingw/msys you must use <drive>:/<install path> or you will have include path problems"
	echo "this is the top level directory for devkitpro, i.e. e:/devkitPro"

	read INSTALLDIR
	echo
fi

[ ! -z "$INSTALLDIR" ] && mkdir -p $INSTALLDIR && touch $INSTALLDIR/nonexistantfile && rm $INSTALLDIR/nonexistantfile || exit 1;

if test "`curl -V`"; then
	FETCH="curl -f -L -O"
elif test "`wget -V`"; then
	FETCH=wget
else
	echo "ERROR: Please make sure you have wget or curl installed."
	exit 1
fi


#---------------------------------------------------------------------------------
# find proper make
#---------------------------------------------------------------------------------
if [ -z "$MAKE" -a -x "$(which gnumake)" ]; then MAKE=$(which gnumake); fi
if [ -z "$MAKE" -a -x "$(which gmake)" ]; then MAKE=$(which gmake); fi
if [ -z "$MAKE" -a -x "$(which make)" ]; then MAKE=$(which make); fi
if [ -z "$MAKE" ]; then
  echo no make found
  exit 1
fi
echo use $MAKE as make
export MAKE

#---------------------------------------------------------------------------------
# Add installed devkit to the path, adjusting path on minsys
#---------------------------------------------------------------------------------
TOOLPATH=$(echo $INSTALLDIR | sed -e 's/^\([a-zA-Z]\):/\/\1/')
export PATH=$PATH:$TOOLPATH/$package/bin

if [ ! -z $CROSSBUILD ]; then
	prefix=$INSTALLDIR/$CROSSBUILD/$package
	CROSS_PARAMS="--build=`./config.guess` --host=$CROSSBUILD"
else
	prefix=$INSTALLDIR/$package
fi

if [ "$CROSSBUILD" = "i686-w64-mingw32" ]; then
	export PKG_CONFIG_PATH=/opt/i686-w64-mingw32/mingw/lib/pkgconfig
fi

if [ "$BUILD_DKPRO_AUTOMATED" != "1" ] ; then

	echo
	echo 'Ready to install '$package' in '$INSTALLDIR
	echo
	echo 'press return to continue'

	read dummy
fi
PLATFORM=`uname -s`

case $PLATFORM in
	Darwin )
		cflags="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch i386 -arch ppc"
		ldflags="-mmacosx-version-min=10.4 -arch i386 -arch ppc -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk"
		export CC=gcc-4.0
		export CXX=g++-4.0
    ;;
	MINGW32* )
		cflags="-D__USE_MINGW_ACCESS"
# horrid hack to get -flto to work on windows
		plugin_ld="--with-plugin-ld=ld"
    ;;
esac

BUILDSCRIPTDIR=$(pwd)
BUILDDIR=$(pwd)/.$package
if [ ! -z $CROSSBUILD ]; then
	BUILDDIR=$BUILDDIR-$CROSSBUILD
fi
DEVKITPRO_URL="http://downloads.sourceforge.net/devkitpro/"
DATAPLUS_URL="https://github.com/downloads/brijohn/"

patchdir=$(pwd)/$basedir/patches
scriptdir=$(pwd)/$basedir/scripts

archives="binutils-${BINUTILS_VER}.tar.bz2 gcc-${GCC_VER}.tar.bz2 newlib-${NEWLIB_VER}.tar.gz gdb-${GDB_VER}.tar.bz2"

if [ $VERSION -eq 1 ]; then
	targetarchives="libnds-src-${LIBNDS_VER}.tar.bz2 libgba-src-${LIBGBA_VER}.tar.bz2
		libmirko-src-${LIBMIRKO_VER}.tar.bz2 dswifi-src-${DSWIFI_VER}.tar.bz2 maxmod-src-${MAXMOD_VER}.tar.bz2
		default-arm7-src-${DEFAULT_ARM7_VER}.tar.bz2 libfilesystem-src-${FILESYSTEM_VER}.tar.bz2
		libfat-src-${LIBFAT_VER}.tar.bz2"
	hostarchives="gbatools-$GBATOOLS_VER.tar.bz2 grit-$GRIT_VER.tar.bz2 ndstool-$NDSTOOL_VER.tar.bz2
		general-tools-$GENERAL_TOOLS_VER.tar.bz2 dlditool-$DLDITOOL_VER.tar.bz2 mmutil-$MMUTIL_VER.tar.bz2
		dfu-util-$DFU_UTIL_VER.tar.bz2 stlink-$STLINK_VER.tar.bz2"
fi

if [ $VERSION -eq 2 ]; then
	targetarchives="libogc-src-${LIBOGC_VER}.tar.bz2 libfat-src-${LIBFAT_VER}.tar.bz2"
	hostarchives="gxtexconv-$GXTEXCONV_VER.tar.bz2 gcdspsuite-$GCDSPSUITE_VER.tar.bz2
			wiiload-$WIILOAD_VER.tar.bz2 elf2dol-$ELF2DOL_VER.tar.bz2 general-tools-$GENERAL_TOOLS_VER.tar.bz2"
fi

if [ $VERSION -eq 3 ]; then
	targetarchives="pspsdk-src-${PSPSDK_VER}.tar.bz2"
fi

if [ $VERSION -eq 4 ]; then
	gitrepos="git://github.com/brijohn/libdataplus.git"
	hostarchives="general-tools-$GENERAL_TOOLS_VER.tar.bz2 ${DATAPLUS_URL}buildscripts/elf2d01-$ELF2D01_VER.tar.bz2"
fi

if [ ! -z "$BUILD_DKPRO_SRCDIR" ] ; then
	SRCDIR="$BUILD_DKPRO_SRCDIR"
else
	SRCDIR=`pwd`
fi

cd $SRCDIR
for archive in $archives $targetarchives $hostarchives
do
	if [ "`dirname $archive`" = "." ]; then
		archive="${DEVKITPRO_URL}${archive}"
	fi
	echo `basename $archive`
	if [ ! -f `basename $archive` ]; then
		$FETCH $archive || { echo "Error: Failed to download `basename $archive`"; exit 1; }
	fi
done

cd $BUILDSCRIPTDIR
mkdir -p $BUILDDIR
cd $BUILDDIR

for repo in $gitrepos
do
	git_clone_project $repo master
done

extract_and_patch binutils $BINUTILS_VER bz2
extract_and_patch gcc $GCC_VER bz2
rm -fr gcc-$GCC_VER/zlib
extract_and_patch newlib $NEWLIB_VER gz
extract_and_patch gdb $GDB_VER bz2

for archive in $targetarchives
do
	archive=`basename $archive`
	destdir=$(echo $archive | sed -e 's/\(.*\)-src-\(.*\)\.tar\.bz2/\1-\2/' )
	echo $destdir
	if [ ! -d $destdir ]; then
		mkdir -p $destdir
		bzip2 -cd $SRCDIR/$archive | tar -xf - -C $destdir || { echo "Error extracting "$archive; exit 1; }
	fi
done

for archive in $hostarchives
do
	archive=`basename $archive`
	tar -xjf $SRCDIR/$archive
done

#---------------------------------------------------------------------------------
# Build and install devkit components
#---------------------------------------------------------------------------------
if [ -f $scriptdir/build-gcc.sh ]; then . $scriptdir/build-gcc.sh || { echo "Error building toolchain"; exit 1; }; cd $BUILDSCRIPTDIR; fi
if [ -f $scriptdir/build-tools.sh ]; then . $scriptdir/build-tools.sh || { echo "Error building tools"; exit 1; }; cd $BUILDSCRIPTDIR; fi
if [ -f $scriptdir/build-crtls.sh ]; then . $scriptdir/build-crtls.sh || { echo "Error building crtls"; exit 1; }; cd $BUILDSCRIPTDIR; fi

if [ "$CROSSBUILD" = "i686-w64-mingw32" ]; then
	if [ $VERSION -ne 3 ]; then
		cp -v 	/opt/i686-w64-mingw32/mingw/lib/FreeImage.dll $prefix/bin
	fi
	if [ $VERSION -eq 1 ]; then
		cp -v /opt/i686-w64-mingw32/i686-w64-mingw32/bin/libusb-1.0.dll $prefix/bin
	fi
	cp -v	/opt/i686-w64-mingw32/mingw/lib/libstdc++-6.dll \
		/opt/i686-w64-mingw32/mingw/lib/libgcc_s_sjlj-1.dll \
		$prefix/bin
fi

echo "stripping installed binaries"
. ./strip_bins.sh

#---------------------------------------------------------------------------------
# Clean up temporary files and source directories
#---------------------------------------------------------------------------------

cd $BUILDSCRIPTDIR

if [ "$BUILD_DKPRO_AUTOMATED" != "1" ] ; then
	echo
	echo "Would you like to delete the build folders and patched sources? [Y/n]"
	read answer
else
	answer=y
fi

if [ "$answer" != "n" -a "$answer" != "N" ]; then

	echo "Removing patched sources and build directories"
	rm -fr $BUILDDIR
fi


echo
echo "note: Add the following to your environment;  DEVKITPRO=$TOOLPATH $toolchain=$TOOLPATH/$package"
echo
