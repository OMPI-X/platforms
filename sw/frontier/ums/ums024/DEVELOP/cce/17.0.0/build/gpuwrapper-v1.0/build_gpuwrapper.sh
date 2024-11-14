#!/bin/bash

# TJN: CRUSHER umask to maintain group write
umask 0002

SRC_FILE=/sw/frontier/ums/ums024/DEVELOP/cce/17.0.0/build/gpuwrapper-v1.0/gpuwrapper.sh

# Path to OMPI bin directory where we want to place script
#DST_DIR=/sw/frontier/ums/ums024/DEVELOP/cce/15.0.0/install/openmpi-5.0.0-ompix-a2-20231109.debug/bin

#DST_DIR=/sw/frontier/ums/ums024/DEVELOP/cce/17.0.0/install/openmpi-devel-tjn-20240802/bin
DST_DIR=/sw/frontier/ums/ums024/DEVELOP/cce/17.0.0/install/openmpi-5.0.6rc1-tjn-20241111/bin

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

install -v $SRC_FILE $DST_DIR/

