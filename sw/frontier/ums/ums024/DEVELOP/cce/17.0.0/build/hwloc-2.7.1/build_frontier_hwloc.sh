#!/bin/bash

# TJN: FRONTIER umask to maintain group write
umask 0002

die() {
    msg=$1
    echo "##########################################################"
    echo "#"
    echo "# ERROR: $msg"
    echo "#"
    echo "##########################################################"
    exit 1
}

COMPILER=cce
COMPILER_VER=17.0.0

PKG_NAME=hwloc
PKG_VER=2.7.1

build_date=$(date "+%Y%m%d")
DBGEXT=""

MY_UMS_BASE_DIR=/sw/frontier/ums/ums024/DEVELOP

MY_PKG_PREFIX=$MY_UMS_BASE_DIR/$COMPILER/$COMPILER_VER/install/${PKG_NAME}-${PKG_VER}-${build_date}${DBGEXT}

MY_PROGENV=PrgEnv-cray
MY_CC=craycc
MY_CXX=craycxx

#MY_PROGENV=PrgEnv-gnu
#MY_CC=gcc
#MY_CXX=g++

# LOAD MODULES FIRST SO WE HAVE ENV VARS!!!!

# MODULE CONFIGURATIONS
module unload cray-mpich
module unload cray-pmi-lib
module unload cray-pmi

module load libtool

module load   $COMPILER/$COMPILER_VER
module use    $MY_UMS_BASE_DIR/$COMPILER/$COMPILER_VER/modules

module is-loaded $MY_PROGENV || die "Missing $MY_PROGENV"

module unload darshan-runtime
module unload cray-libsci

module list
sleep 2

# XXX: EDIT THESE PATHS ACCORDINGLY
#MY_OFI_DIR=$(pkg-config --variable=prefix libfabric)


echo "#------------------------------------------------"
echo "# Using:"
echo "#"
echo "#      $MY_PROGENV"
echo "#        CC=$MY_CC"
echo "#        CXX=$MY_CXX"
echo "#"
#echo "#       MY_OFI_DIR=$MY_OFI_DIR"
echo "#"
echo "#   MY_PKG_PREFIX=$MY_PKG_PREFIX"
echo "#"
echo "#------------------------------------------------"
sleep 5

#############

if [ ! -f "../../../../source/${PKG_NAME}-${PKG_VER}/configure" ] ; then
    echo "ERROR: Failed sanity check on ${PKG_NAME} configure file!"
    echo "  Missing: ../../../../source/${PKG_NAME}-${PKG_VER}/configure"
    exit 1
fi

if [ -d "$MY_PKG_PREFIX" ] ; then
    echo "ERROR: Directory already exists! (already 'installed'?)"
    echo "   $MY_PKG_PREFIX"
    exit 1
fi

echo "# START: `date`"

# TJN: Export these two envvars just incase wrapper not recognize
CC=craycc
CXX=craycxx
#    -Wno-strict-prototypes CXXFLAGS=-Wno-strict-prototypes \

../../../../source/${PKG_NAME}-${PKG_VER}/configure \
    --prefix=${MY_PKG_PREFIX} \
    CC=craycc CXX=craycxx \
    CFLAGS=-Wno-deprecated-non-prototype CXXFLAGS=-Wno-deprecated-non-prototype \
    || die "configure failed - skip make" \
&& make -j 4    || die "make failed - skip make install" \
&& make install || die "make install failed - badness"


echo "####################################################"
echo "#"
echo "#      $MY_PROGENV"
echo "#        CC=$MY_CC"
echo "#        CXX=$MY_CXX"
echo "#"
#echo "#       MY_OFI_DIR=$MY_OFI_DIR"
echo "#"
echo "#   MY_PKG_PREFIX=$MY_PKG_PREFIX"
echo "#"
echo "# Set following in modulefile:"
echo "#  PREFIX=$MY_PKG_PREFIX"
echo "#"
echo "####################################################"
echo "# END: `date`"

exit 0
