#!/bin/bash

# If command fails the script exits
try () {
	if [ $VERBOSE -eq 1 ]; then
		"$@" | tee -a $OUTPUT_FILE 2>&1 || exit -1
	else
		"$@" >> $OUTPUT_FILE 2>&1 || exit -1
	fi
}

# Prepares the directory structure needed for the compilation and any additional
# requirement
prepare() {
	# ImageMagick requires crt_externals.h, that doesn't
	# exist for the iPhone - Just copying it make things compile/work
	if [ -e $IOSSDKROOT/usr/include/crt_externs.h ]; then
		:;
	else
		echo "[INFO] need to copy crt_externals.h for compilation, please enter sudo password"
		sudo ln -s "$SIMSDKROOT/usr/include/crt_externs.h" "$IOSSDKROOT/usr/include/crt_externs.h"
	fi
	
	# Check if IMDelegates is inside the IM directory or link it
	if [ -e $IM_DELEGATES_DIR ]; then
		:;
	else
		echo "[INFO] IMDelegates not found, linking it"
		ln -s "$BUILDROOT/IMDelegates" "$IM_DIR/IMDelegates"
	fi
	
	# target folder
	mkdir -p $TARGET_LIB_DIR
	# includes
	mkdir -p $LIB_DIR/include/im_config
	mkdir -p $LIB_DIR/include/jpeg
	mkdir -p $LIB_DIR/include/magick
	mkdir -p $LIB_DIR/include/png
	mkdir -p $LIB_DIR/include/tiff
	mkdir -p $LIB_DIR/include/wand
	# lib directories
	mkdir -p $JPEG_LIB_DIR
	mkdir -p $PNG_LIB_DIR
	mkdir -p $TIFF_LIB_DIR
	# DYLIB directories
	for i in "jpeg" "png" "tiff"; do
		for j in $ARCHS; do
			mkdir -p $LIB_DIR/${i}_${j}_dylib
		done
	done
}

# For every architecture checks if the coresponding library file exists. Used
# later to merge (with lipo) all the library archives in a fat one
check_for_archs() {
	local to_check=$1
	local ret="OK"
	for i in $ARCHS; do
		if [ ! -e $to_check.$i ]; then
			ret="NO"
			break
		fi
	done
	echo $ret
}

# Creates the structure that can be imported in XCode as it is done in the
# example project
structure_for_xcode() {
	echo "[+ Prepairing import for XCode]"
	if [ -e $FINAL_DIR ]; then
		echo "[|- RM $FINAL_DIR/*]"
		try rm -rf ${FINAL_DIR}/*
	else
		echo "[|- MKDIR: $FINAL_DIR]"
		try mkdir -p ${FINAL_DIR}
	fi
	echo "[|- CP ...]"
	try cp -r ${LIB_DIR}/include/ ${FINAL_DIR}/include/
	try cp ${LIB_DIR}/*.a ${FINAL_DIR}/
	echo "[+ DONE!]"
}