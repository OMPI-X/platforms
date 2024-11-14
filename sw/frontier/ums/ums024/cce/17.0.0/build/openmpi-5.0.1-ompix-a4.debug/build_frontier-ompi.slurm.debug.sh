#!/bin/bash

# TJN: umask to maintain group write
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

# TJN: BUILDING WITHOUT SLURM SUPPORT!
ompi_ver=5.0.1
frontier_release=ompix-a4
frontier_source=ompix-a4

build_date=$(date "+%Y%m%d")
DBGEXT=".dbg"

MY_UMS_BASE_DIR=/sw/frontier/ums/ums024

MY_OMPI_PREFIX=$MY_UMS_BASE_DIR/$COMPILER/$COMPILER_VER/install/openmpi-${ompi_ver}-${frontier_release}-${build_date}${DBGEXT}
OMPI_SOURCE_DIR=../../../../source/openmpi-${ompi_ver}-${frontier_source}


MY_PROGENV=PrgEnv-cray
MY_CC=craycc
MY_CXX=craycxx

# LOAD MODULES FIRST SO WE HAVE ENV VARS!!!!

# MODULE CONFIGURATIONS
module unload cray-mpich
module unload cray-pmi-lib
module unload cray-pmi
module unload craype-network-ucx
module unload craype-network-ofi

module unload openmpi

module load   $COMPILER/$COMPILER_VER
module use    $MY_UMS_BASE_DIR/$COMPILER/$COMPILER_VER/modules

module is-loaded $MY_PROGENV || die "Missing $MY_PROGENV"

module load libtool

module load rocm/5.7.1
module load xpmem
module load libfabric/ornl-v1.20.0-ompix-a4.debug

#module load cray-python/3.9.12.1
module load cray-python/3.9.13.1
source /sw/frontier/ums/ums024/cce/17.0.0/build/openmpi-5.0.1-ompix-a4.debug/ve3/bin/activate
echo "Cython location:"
which cython

module list
sleep 2

# XXX: EDIT THESE PATHS ACCORDINGLY
MY_OFI_DIR=$(pkg-config --variable=prefix libfabric)
MY_XPMEM_DIR=$(pkg-config --variable=prefix cray-xpmem)
MY_ROCM_DIR=$ROCM_PATH


echo "#------------------------------------------------"
echo "# Using:"
echo "#"
echo "#  Build UMASK=$(umask)"
echo "#"
echo "#   $MY_PROGENV"
echo "#      CC=$MY_CC"
echo "#      CXX=$MY_CXX"
echo "#   MY_UMS_BASE_DIR=$MY_UMS_BASE_DIR"
echo "#"
echo "#    MY_OFI_DIR=$MY_OFI_DIR"
echo "#  MY_XPMEM_DIR=$MY_XPMEM_DIR"
echo "#   MY_ROCM_DIR=${MY_ROCM_DIR}"
echo "#"
echo "#   OMPI_SOURCE_DIR=${OMPI_SOURCE_DIR}"
echo "#"
echo "#   MY_OMPI_PREFIX=$MY_OMPI_PREFIX"
echo "#"
echo "#      ** DEBUG Enabled **"
echo "#      ** Disable gpfs support **"
echo "#------------------------------------------------"
sleep 5

#############
export OMPI_INSTALL_DIR=${MY_OMPI_PREFIX}

echo "# START: `date`"

if [ ! -f ${OMPI_SOURCE_DIR}/configure ] ; then
    echo "Error: Bad path to source - '${OMPI_SOURCE_DIR}'"
    exit 1
fi

#      --enable-debug \
#      --with-devel-headers \

${OMPI_SOURCE_DIR}/configure \
        --enable-debug \
        --with-devel-headers \
        --without-gpfs \
      --with-slurm \
     --enable-python-bindings \
    --enable-mpirun-prefix-by-default \
    --prefix=${OMPI_INSTALL_DIR} \
    --disable-vt \
    --enable-mpi1-compatibility \
    --with-memory-manager=none \
    --with-rocm=${MY_ROCM_DIR} \
    --with-ofi=${MY_OFI_DIR} \
    --with-xpmem=${MY_XPMEM_DIR} \
    CC=craycc CXX=craycxx \
    || die "configure failed - skip make" \
&& make -j 4    || die "make failed - skip make install" \
&& make -j 4 all   || die "make-all failed - skip make install" \
&& make install || die "make install failed - badness"

PYVER=3.9
echo "####################################################"
echo "#"
echo "#      $MY_PROGENV"
echo "#        CC=$MY_CC"
echo "#        CXX=$MY_CXX"
echo "#"
echo "#      MY_OFI_DIR=$MY_OFI_DIR"
echo "#    MY_XPMEM_DIR=$MY_XPMEM_DIR"
echo "#     MY_ROCM_DIR=${MY_ROCM_DIR}"
echo "#"
echo "#      OMPI_INSTALL_DIR=$OMPI_INSTALL_DIR"
echo "#      PYTHONPATH=$OMPI_INSTALL_DIR/lib/python$PYVER/site-packages/pypmix-6.0.0-py$PYVER-linux-$(uname -m).egg"
echo "#"
echo "#      ** SLURM Enabled **"
echo "#      ** DEBUG Enabled **"
echo "#      ** Disable gpfs support **"
echo "####################################################"
echo "# END: `date`"
