#!/bin/bash

# TJN: CRUSHER umask to maintain group write
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

# TODO: FIXME SHOULD BE USING gcc/
COMPILER=cce
COMPILER_VER=17.0.0

ofi_ver=ornl-v1.20.0
frontier_release=ompix-a4

build_date=$(date "+%Y%m%d")
DBGEXT=""

MY_UMS_BASE_DIR=/sw/frontier/ums

MY_OFI_PREFIX=$MY_UMS_BASE_DIR/ums024/$COMPILER/$COMPILER_VER/install/libfabric-${ofi_ver}-${frontier_release}-${build_date}${DBGEXT}
OFI_SOURCE_DIR=../../../../source/libfabric-${ofi_ver}-${frontier_release}

MY_PROGENV=PrgEnv-cray
MY_CC=craycc
MY_CXX=craycxx

# LOAD MODULES FIRST SO WE HAVE ENV VARS!!!!

# MODULE CONFIGURATIONS
module unload cray-mpich
module unload libfabric
module unload craype-network-ofi

module load $COMPILER/$COMPILER_VER
module use  $MY_UMS_BASE_DIR/ums024/$COMPILER/$COMPILER_VER/modules

echo "module load   $COMPILER/$COMPILER_VER"
echo "module use $MY_UMS_BASE_DIR/ums024/$COMPILER/$COMPILER_VER/modules"

module load libtool
module load craype-accel-amd-gfx90a
module load rocm/5.7.1
module load xpmem

# TJN: load json-c last to make sure our version wins over system version
module load json-c/0.17

module unload darshan-runtime
module list
sleep 2

MY_ROCM_DIR=$ROCM_PATH
MY_JSONC_DIR=$(pkg-config --variable=prefix json-c)
MY_LIBCXI_DIR=$(pkg-config --variable=prefix libcxi)
XPMEM_DIR=$(pkg-config --variable=prefix cray-xpmem)

echo "#------------------------------------------------"
echo "# Using:"
echo "#"
echo "#  Build UMASK=$(umask)"
echo "#"
echo "#      $MY_PROGENV"
echo "#        CC=$MY_CC"
echo "#        CXX=$MY_CXX"
echo "#"
echo "#        MY_ROCM_DIR=${MY_ROCM_DIR}"
echo "#       MY_JSONC_DIR=${MY_JSONC_DIR}"
echo "#          XPMEM_DIR=${XPMEM_DIR}"
echo "#      MY_LIBCXI_DIR=${MY_LIBCXI_DIR}"
echo "#"
echo "#       MY_OFI_PREFIX=${MY_OFI_PREFIX}"
echo "#"
echo "#------------------------------------------------"
sleep 5

#############

export OFI_INSTALL_DIR=${MY_OFI_PREFIX}

if [ ! -d "$MY_UMS_BASE_DIR/ums024/$COMPILER/$COMPILER_VER/modules" ] ; then
    echo "ERROR: Failed sanity check on directory for compiler install"
    exit 1
fi

if [ ! -f "${OFI_SOURCE_DIR}/configure" ] ; then
    echo "ERROR: Failed sanity check on OFI configure file!"
    echo "  Missing: ${OFI_SOURCE_DIR}/configure"
    exit 1
fi

echo "# START: `date`"

export PE_MPICH_GTL_DIR_amd_gfx90a="-L${CRAY_MPICH_ROOTDIR}/gtl/lib"
export PE_MPICH_GTL_LIBS_amd_gfx90a="-lmpi_gtl_hsa"

#    CC=craycc CXX=craycxx \
export CC=gcc
${OFI_SOURCE_DIR}/configure \
    --prefix=${OFI_INSTALL_DIR} \
    --disable-opx \
    --enable-cxi \
    --enable-xpmem=${XPMEM_DIR} \
    --with-rocr=${MY_ROCM_DIR} \
    --verbose \
    CFLAGS="-D__SSE4_1__ -D__HIP_PLATFORM_HCC__ -I ${ROCM_PATH}/include -I${MY_JSONC_DIR}/include " \
    LDFLAGS="-L${ROCM_PATH}/lib -lamdhip64 -lhsa-runtime64 -L${MY_JSONC_DIR}/lib64" \
    CC=gcc \
    || die "configure failed - skip make" \
&& make -j8     || die "make failed - skip make install" \
&& make install || die "make install failed - badness"

echo "####################################################"
echo "#"
echo "#      $MY_PROGENV"
echo "#        CC=$MY_CC"
echo "#        CXX=$MY_CXX"
echo "#      **OVERRIDE** USED GCC"
echo "#"
echo "#        MY_ROCM_DIR=${MY_ROCM_DIR}"
echo "#       MY_JSONC_DIR=${MY_JSONC_DIR}"
echo "#          XPMEM_DIR=${XPMEM_DIR}"
echo "#      MY_LIBCXI_DIR=${MY_LIBCXI_DIR}"
echo "#"
echo "#    OFI_INSTALL_DIR=${OFI_INSTALL_DIR}"
echo "#"
echo "####################################################"
echo "# END: `date`"
