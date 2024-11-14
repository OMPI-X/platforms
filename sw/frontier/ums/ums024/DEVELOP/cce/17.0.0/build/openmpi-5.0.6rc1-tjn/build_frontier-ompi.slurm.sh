#!/bin/bash

# INCLUDE SPHINX

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

COMPILER=cce
COMPILER_VER=17.0.0

# TJN: BUILDING WITHOUT SLURM SUPPORT!
ompi_ver=5.0.6rc1-tjn
#frontier_release=-ompix-a3
frontier_release=

build_date=$(date "+%Y%m%d")
DBGEXT=""

MY_UMS_BASE_DIR=/sw/frontier/ums/ums024/DEVELOP

MY_OMPI_PREFIX=$MY_UMS_BASE_DIR/$COMPILER/$COMPILER_VER/install/openmpi-${ompi_ver}${frontier_release}-${build_date}${DBGEXT}
OMPI_SOURCE_DIR=../../../../source/openmpi-${ompi_ver}${frontier_release}

# XXX: sphinx
MY_VENV_DIR=/sw/frontier/ums/ums024/DEVELOP/$COMPILER/$COMPILER_VER/build/openmpi-devel-tjn/venv

MY_PROGENV=PrgEnv-cray
MY_CC=craycc
MY_CXX=craycxx

# LOAD MODULES FIRST SO WE HAVE ENV VARS!!!!

# MODULE CONFIGURATIONS
module unload cray-mpich
module unload cray-pmi-lib
module unload cray-pmi

module unload openmpi

module load   $COMPILER/$COMPILER_VER
module use    $MY_UMS_BASE_DIR/$COMPILER/$COMPILER_VER/modules

module is-loaded $MY_PROGENV || die "Missing $MY_PROGENV"

module load libtool

module load rocm/5.7.1
module load xpmem
#module load libfabric/ornl-v1.20.0-ompix-a4
module load libfabric/public-tjn
#module load libfabric/devel-tjn

module load cray-python/3.11.5
source /sw/frontier/ums/ums024/DEVELOP/cce/17.0.0/build/openmpi-${ompi_ver}/venv-3.11/bin/activate
echo "###"
echo "# Cython location:"
which cython
echo "###"
sleep 2

# XXX: sphinx
source $MY_VENV_DIR/bin/activate
echo "###"
echo "# sphinx location:"
which sphinx-build
echo "###"
sleep 2

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
echo "#   MY_VENV_DIR=${MY_VENV_DIR}"
echo "#"
echo "#   MY_OMPI_PREFIX=$MY_OMPI_PREFIX"
echo "#"
#echo "#      ** DEBUG Enabled **"
#echo "#      ** DEBUG sphinx in VENV**"
#which sphinx-build
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
#     --enable-python-bindings \

#    CC=craycc CXX=craycxx \
#      --enable-debug \
#      --with-devel-headers \
${OMPI_SOURCE_DIR}/configure \
      --with-slurm \
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
#echo "#      PYTHONPATH=$OMPI_INSTALL_DIR/lib/python$PYVER/site-packages/pypmix-6.0.0-py$PYVER-linux-$(uname -m).egg"
echo "#"
echo "#      ** SLURM Enabled **"
#echo "#      ** DEBUG Enabled **"
echo "####################################################"
echo "# END: `date`"
