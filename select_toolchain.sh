#!/bin/bash
VERSION=0
while [ $VERSION -eq 0 ]
do
  echo
  echo "Please select the toolchain you require"
  echo
  echo "1: devkitARM (gba gp32 ds)"
  echo "2: devkitPPC (gamecube wii)"
  echo "3: devkitPSP (PSP)"
  echo "4: devkitSH4 (exword)"
  read VERSION

  if [ "$VERSION" -ne 1 -a "$VERSION" -ne 2 -a "$VERSION" -ne 3 -a "$VERSION" -ne 4 ]
  then
      VERSION=0
  fi
done

case "$VERSION" in
  "1" )
    GCC_VER=4.7.0
    BINUTILS_VER=2.22
    NEWLIB_VER=1.20.0
    GDB_VER=7.4
    basedir='dkarm-eabi'
    package=devkitARM
    target=arm-eabi
    toolchain=DEVKITARM
  ;;
  "2" )
    GCC_VER=4.6.3
    BINUTILS_VER=2.22
    NEWLIB_VER=1.20.0
    GDB_VER=7.4
    basedir='dkppc'
    package=devkitPPC
    target=powerpc-eabi
    toolchain=DEVKITPPC
  ;;
  "3" )
    GCC_VER=4.6.3
    BINUTILS_VER=2.22
    NEWLIB_VER=1.20.0
    GDB_VER=7.4
    basedir='dkpsp'
    package=devkitPSP
    target=psp
    toolchain=DEVKITPSP
  ;;
  "4" )
    GCC_VER=4.7.0
    BINUTILS_VER=2.22
    NEWLIB_VER=1.19.0
    GDB_VER=7.4
    basedir='dksh4'
    package=devkitSH4
    builddir=sh-elf
    target=sh-elf
    toolchain=DEVKITSH4
  ;;
esac
