#!/bin/bash

if [[ $# != 1 ]]; then
	echo "$0 takes 1 argument: the version of ImageMagick you want to compile!"
	echo "EXAMPLE: $0 6.8.8-2"
	exit
fi

export IM_VERSION="$1"

# Configuration / Function scripts
. $(dirname $0)/env.sh   # environment variables
. $(dirname $0)/flags.sh # compiler flags
. $(dirname $0)/utils.sh # various functions
# Compilation scripts
. $(dirname $0)/compile_png.sh  # libPNG
. $(dirname $0)/compile_jpeg.sh # JPEG
. $(dirname $0)/compile_tiff.sh # TIFF
. $(dirname $0)/compile_im.sh   # ImageMagick

# --- CLEAN IS SPECIAL --- #
if [[ $1 == "clean" ]]; then
	echo "Cleaning..."
	rm *.log 2>/dev/null
	rm -r ${TARGET_LIB_DIR}/ 2>/dev/null
	rm -r ${FINAL_DIR}/ 2>/dev/null
	echo "Done!"
	exit 0
fi

# --- ZIP IS SPECIAL --- #
# Used by Claudio Marforio to generate zips for the imagemagick FTP
if [[ $1 == "zip" ]]; then
	zip_for_ftp
	exit 0
fi

# --- WHAT GETS EXECUTED --- #
prepare

for i in $ARCHS; do
	png $i
	jpeg $i
	tiff $i
	im $i
done

structure_for_xcode
