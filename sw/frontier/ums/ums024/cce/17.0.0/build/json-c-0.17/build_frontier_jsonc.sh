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

PKG_VER=0.17

build_date=$(date "+%Y%m%d")
DBGEXT=""

MY_UMS_BASE_DIR=/sw/frontier/ums

MY_JSONC_PREFIX=$MY_UMS_BASE_DIR/ums024/$COMPILER/$COMPILER_VER/install/json-c-${PKG_VER}-${build_date}${DBGEXT}

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
module use    $MY_UMS_BASE_DIR/ums024/$COMPILER/$COMPILER_VER/modules

module is-loaded $MY_PROGENV || die "Missing $MY_PROGENV"

module unload darshan-runtime

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
echo "#   MY_JSONC_PREFIX=$MY_JSONC_PREFIX"
echo "#"
echo "#------------------------------------------------"
sleep 5

#############
export JSONC_INSTALL_DIR=${MY_JSONC_PREFIX}

if [ ! -f "../../../../source/json-c-${PKG_VER}/cmake-configure" ] ; then
    echo "ERROR: Failed sanity check on JSON-C cmake-configure file!"
    echo "  Missing: ../../../../source/json-c-${PKG_VER}/cmake-configure"
    exit 1
fi

if [ -d "$MY_JSONC_PREFIX" ] ; then
    echo "ERROR: Directory already exists! (already 'installed'?)"
    echo "   $MY_JSONC_PREFIX"
    exit 1
fi

echo "# START: `date`"

# TJN: Export these two envvars just incase cmake wrapper not recognize
CC=craycc
CXX=craycxx

../../../../source/json-c-${PKG_VER}/cmake-configure \
    --prefix=${JSONC_INSTALL_DIR} \
    CC=craycc CXX=craycxx \
    || die "configure failed - skip make" \
&& make -j 4    || die "make failed - skip make install" \
&& make install || die "make install failed - badness"

echo "####################################################"
echo "#"
echo "#      $MY_PROGENV"
echo "#        CC=$MY_CC"
echo "#        CXX=$MY_CXX"
echo "#"
echo "#       MY_OFI_DIR=$MY_OFI_DIR"
echo "#"
echo "# JSONC_INSTALL_DIR=$JSONC_INSTALL_DIR"
echo "#"
echo "####################################################"
echo "# END: `date`"
