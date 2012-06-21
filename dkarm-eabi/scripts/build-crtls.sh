#!/bin/sh

export DEVKITPRO=$TOOLPATH
export DEVKITARM=$DEVKITPRO/devkitARM

#---------------------------------------------------------------------------------
# copy base rulesets
#---------------------------------------------------------------------------------
cp -v $BUILDSCRIPTDIR/dkarm-eabi/rules/* $prefix

#---------------------------------------------------------------------------------
# Install and build the gba crt
#---------------------------------------------------------------------------------

cp -v $BUILDSCRIPTDIR/dkarm-eabi/crtls/* $prefix/arm-eabi/lib/
cd $prefix/arm-eabi/lib/
$MAKE CRT=gba
$MAKE CRT=gp32
$MAKE CRT=er
$MAKE CRT=gp32_gpsdk
$MAKE CRT=ds_arm7
$MAKE CRT=ds_arm9
$MAKE CRT=ds_cart

cd $BUILDDIR/libnds-$LIBNDS_VER
$MAKE || { echo "error building libnds"; exit 1; }
$MAKE install || { echo "error installing libnds"; exit 1; }

cd $BUILDDIR/dswifi-$DSWIFI_VER
$MAKE || { echo "error building dswifi"; exit 1; }
$MAKE install || { echo "error installing dswifi"; exit 1; }

cd $BUILDDIR/default-arm7-$DEFAULT_ARM7_VER
$MAKE || { echo "error building default arm7"; exit 1; }
$MAKE install || { echo "error installing default arm7"; exit 1; }

cd $BUILDDIR/libfat-$LIBFAT_VER
$MAKE nds-install || { echo "error building nds libfat"; exit 1; }
$MAKE gba-install || { echo "error installing gba libfat"; exit 1; }

cd $BUILDDIR/maxmod-$MAXMOD_VER
$MAKE || { echo "error building maxmod"; exit 1; }
$MAKE install || { echo "error installing maxmod"; exit 1; }

cd $BUILDDIR/libmirko-$LIBMIRKO_VER
$MAKE || { echo "error building libmirko"; exit 1; }
$MAKE install || { echo "error installing libmirko"; exit 1; }

cd $BUILDDIR/libfilesystem-$FILESYSTEM_VER
$MAKE || { echo "error building libfilesystem"; exit 1; }
$MAKE install || { echo "error installing libfilesystem"; exit 1; }
