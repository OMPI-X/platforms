#!/bin/bash

# TJN: CRUSHER umask to maintain group write
umask 0002

SRC_FILE=/sw/frontier/ums/ums024/cce/17.0.0/build/gpuwrapper-v1.0/gpuwrapper.sh

# Path to OMPI bin directory where we want to place script
#DST_DIR=/sw/frontier/ums/ums024/cce/17.0.0/install/openmpi-XXXXX/bin
DST_DIR=/sw/frontier/ums/ums024/cce/17.0.0/install/openmpi-5.0.1-ompix-a4-20240828/bin

echo "#------------------------------------------------"
echo "# Using:"
echo "#"
echo "#  Build UMASK=$(umask)"
echo "#"
echo "#    SRC_FILE=${SRC_FILE}"
echo "#    DST_DIR=${DST_DIR}"
echo "#"
echo "#------------------------------------------------"
sleep 5

if [ ! -d $DST_DIR ] ; then
    echo "ERROR: Missing destination dir '$DST_DIR'"
    exit 1
fi

install -v $SRC_FILE $DST_DIR/

