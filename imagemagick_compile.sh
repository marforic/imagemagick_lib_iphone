#!/bin/bash

# Author: Claudio Marforio
# e-mail: marforio@gmail.com
# date: 21.03.2011

# Script to make static libraries (jpeg + png + tiff) and ImageMagick
# the libraries will be conbined into i386 + armv6 + armv7 static
# libraries to be used inside an XCODE project for iOS development

# The directory structure has to be:
# ./cross_compile/ImageMagick-VERSION/ <- ImageMagick top directory
#       |        /IMDelegataes/	       <- Some delegates: jpeg + png + tiff
#       |           |-jpeg-8c/         <- jpeg-8c -- no need to patch it
#       |           |-libpng-1.4.5     <- png lib -- no need to patch it
#       |           |-tiff-3.9.4       <- tiff lib -- no need to patch it
#       |- ...	 <- we don't care what's here! :)

# If you don't have this directory structure you can either create it
# or try change around the script

# If everything works correctly you will end up with a folder called
# IMPORT_ME in your working directory (i.e. .) ready to be imported
# into XCode change this line if you want for everything to be
# exported somewhere else

FINAL_DIR=`pwd`/IMPORT_ME/

if [[ $# != 1 ]]; then
	echo "imagemagick_compile.sh takes 1 argument: the version of ImageMagick that you want to compile!"
	echo "USAGE: imagemagick_compile.sh 6.6.8-5"
	exit
fi

IM_VERSION="$1"
IM_DIR="$(pwd)/ImageMagick-$IM_VERSION"
IM_DELEGATES_DIR="${IM_DIR}/IMDelegates/"

if [ -d $IM_DELEGATES_DIR ]; then
	:;
else
	echo "[INFO] IMDelegates folder not found, copying over"
	cp -r "$(pwd)/IMDelegates" "$IM_DIR/IMDelegates"
fi

JPEG_DIR="$IM_DIR/IMDelegates/jpeg-8c"
PNG_DIR="$IM_DIR/IMDelegates/libpng-1.4.5"
TIFF_DIR="$IM_DIR/IMDelegates/tiff-3.9.4"

OUTPUT_FILE="$(pwd)/imagemagick_log_$(date +%s)"

# Architectures and versions
ARCH_SIM="i386"
ARCH_IPHONE="armv7"
ARCH_IPHONE6="armv6"
GCC_VERSION="4.2.1"
MIN_IPHONE_VERSION="3.1"
IPHONE_SDK_VERSION="4.3"
MACOSX_SDK_VERSION="10.5"
IPHONE="armv6 + armv7"

# Set this to where you want the libraries to be placed (if dir is not present it will be created):
TARGET_LIB_DIR=$(pwd)/tmp_target
LIB_DIR=$TARGET_LIB_DIR/im_libs
JPEG_LIB_DIR=$TARGET_LIB_DIR/libjpeg
PNG_LIB_DIR=$TARGET_LIB_DIR/libpng
TIFF_LIB_DIR=$TARGET_LIB_DIR/libtiff
IM_LIB_DIR=$TARGET_LIB_DIR/imagemagick

# Set the build directories
mkdir -p $TARGET_LIB_DIR
mkdir -p $LIB_DIR/include/im_config
mkdir -p $LIB_DIR/include/jpeg
mkdir -p $LIB_DIR/include/magick
mkdir -p $LIB_DIR/include/png
mkdir -p $LIB_DIR/include/tiff
mkdir -p $LIB_DIR/include/wand
for i in "jpeg" "png" "tiff"; do
	for j in $ARCH_IPHONE $ARCH_IPHONE6 $ARCH_SIM; do
		mkdir -p $LIB_DIR/${i}_${j}_dylib
	done
done
mkdir -p $JPEG_LIB_DIR
mkdir -p $PNG_LIB_DIR
mkdir -p $TIFF_LIB_DIR

# General folders where you have the iPhone compiler + tools
export DEVROOT="/Developer/Platforms/iPhoneOS.platform/Developer"
export SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONE_SDK_VERSION}.sdk"
export MACOSXROOT="/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDK_VERSION}.sdk"

# Compiler flags and config arguments - IPHONE
COMMON_IPHONE_LDFLAGS="-L$SDKROOT/usr/lib/"
COMMON_IPHONE_CFLAGS="-arch $ARCH_IPHONE -miphoneos-version-min=$MIN_IPHONE_VERSION -pipe -Os -isysroot $SDKROOT \
-I$SDKROOT/usr/include -I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/$GCC_VERSION/include/"
COMMON_IPHONE6_CFLAGS="-arch $ARCH_IPHONE6 -miphoneos-version-min=$MIN_IPHONE_VERSION -pipe -Os -isysroot $SDKROOT \
-I$SDKROOT/usr/include -I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/$GCC_VERSION/include/"

COMMON_SIM_LDFLAGS="-L$MACOSXROOT/usr/lib"
COMMON_SIM_CFLAGS="-I$MACOSXROOT/usr/include -I$MACOSXROOT/usr/lib/gcc/i686-apple-darwin10/$GCC_VERSION/include/"

IM_LDFLAGS="-L$LIB_DIR/jpeg_${ARCH_IPHONE}_dylib/ -L$LIB_DIR/png_${ARCH_IPHONE}_dylib/ -L$LIB_DIR/tiff_${ARCH_IPHONE}_dylib/ -L$LIB_DIR"
IM_LDFLAGS6="-L$LIB_DIR/jpeg_${ARCH_IPHONE6}_dylib/ -L$LIB_DIR/png_${ARCH_IPHONE6}_dylib/ -L$LIB_DIR/tiff_${ARCH_IPHONE6}_dylib/ -L$LIB_DIR"
IM_LDFLAGS_SIM="-L$LIB_DIR/jpeg_${ARCH_SIM}_dylib/ -L$LIB_DIR/png_${ARCH_SIM}_dylib/ -L$LIB_DIR/tiff_${ARCH_SIM}_dylib/ -L$LIB_DIR"
IM_IFLAGS="$COMMON_SIM_CFLAGS -I$LIB_DIR/include/jpeg -I$LIB_DIR/include/png -I$LIB_DIR/include/tiff"

############    HACK    ############
# ImageMagick requires this header (crt_externals.h), that doesn't
# exist for the iPhone - Just copying it make things compile/work
if [ -e $SDKROOT/usr/include/crt_externs.h ]; then
	:;
else
	echo "[INFO] need to copy crt_externals.h for compilation, please enter sudo password"
	sudo cp "/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IPHONE_SDK_VERSION.sdk/usr/include/crt_externs.h" \
		"$SDKROOT/usr/include/crt_externs.h"
fi
############    END    ############

###################################
############    PNG    ############
###################################

function png() {

echo ""
echo "[+ PNG: $1]"
cd $PNG_DIR

LIBPATH_png=libpng14.a
LIBPATH_png_dylib=libpng14.dylib

if [ "$1" == "$IPHONE" ]; then ## ARMV7 ##

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS"

echo "[|- CONFIG ${ARCH_IPHONE}]"
./configure prefix=$PNG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin &>$OUTPUT_FILE

echo "[|- CC ${ARCH_IPHONE}]"
make -j2 &>$OUTPUT_FILE
echo "[|- INSTALL ${ARCH_IPHONE}]"
make install &>$OUTPUT_FILE

# cp the static + shared library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.$ARCH_IPHONE
cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_${ARCH_IPHONE}_dylib/libpng.dylib

echo "[|- CLEAN ${ARCH_IPHONE}]"
make distclean &>$OUTPUT_FILE

## ARMV6 ##
export CFLAGS="$COMMON_IPHONE6_CFLAGS"

echo "[|- CONFIG ${ARCH_IPHONE6}]"
./configure prefix=$PNG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin &>$OUTPUT_FILE

echo "[|- CC ${ARCH_IPHONE6}]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static + shared library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.$ARCH_IPHONE6
cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_${ARCH_IPHONE6}_dylib/libpng.dylib

echo "[|- CLEAN ${ARCH_IPHONE6}]"
make distclean &>$OUTPUT_FILE

elif [ "$1" == "$ARCH_SIM" ]; then ## INTEL ##

# Set up environment
export CC=$U_CC
export CFLAGS="$COMMON_SIM_CFLAGS -arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="$U_LDFLAGS" #export LDFLAGS="$COMMON_SIM_LDFLAGS $U_LDFLAGS"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

echo "[|- CONFIG $ARCH_SIM]"
./configure prefix=$PNG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared --enable-static \
--host=i686-apple-darwin10 &>$OUTPUT_FILE

echo "[|- CC $ARCH_SIM]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.$ARCH_SIM
cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_${ARCH_SIM}_dylib/libpng.dylib
# cp the include/* files
cp $PNG_LIB_DIR/include/libpng14/* $LIB_DIR/include/png/

echo "[|- CLEAN $ARCH_SIM]"
make distclean &>$OUTPUT_FILE

echo "[|- COMBINE $ARCH_IPHONE $ARCH_IPHONE6 $ARCH_SIM]"
# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch $ARCH_IPHONE $LIB_DIR/libpng.a.$ARCH_IPHONE \
	-arch $ARCH_IPHONE6 $LIB_DIR/libpng.a.$ARCH_IPHONE6 \
	-arch $ARCH_SIM $LIB_DIR/libpng.a.$ARCH_SIM -create -output $LIB_DIR/libpng.a

fi

echo "[+ DONE: $1]"

} ## END PNG LIBRARY ##

###################################
############    JPEG   ############
###################################

function jpeg() {

echo ""
echo "[+ JPEG: $1]"
cd $JPEG_DIR

LIBPATH_jpeg=libjpeg.a
LIBNAME_jpeg=`basename $LIBPATH_jpeg`

if [ "$1" == "$IPHONE" ]; then ## ARMV7 ##

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS"

echo "[|- CONFIG $ARCH_IPHONE]"
./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin &>$OUTPUT_FILE

echo "[|- CC $ARCH_IPHONE]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static + shared library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.$ARCH_IPHONE
cp $JPEG_LIB_DIR/lib/libjpeg.dylib $LIB_DIR/jpeg_${ARCH_IPHONE}_dylib/libjpeg.dylib

echo "[|- CLEAN $ARCH_IPHONE]"
make distclean &>$OUTPUT_FILE

## ARMV6 ##
export CFLAGS="$COMMON_IPHONE6_CFLAGS"

echo "[|- CONFIG $ARCH_IPHONE6]"
./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin &>$OUTPUT_FILE

echo "[|- CC $ARCH_IPHONE6]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static + shared library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.$ARCH_IPHONE6
cp $JPEG_LIB_DIR/lib/libjpeg.dylib $LIB_DIR/jpeg_${ARCH_IPHONE6}_dylib/libjpeg.dylib

echo "[|- CLEAN $ARCH_IPHONE6]"
make distclean &>$OUTPUT_FILE

elif [ "$1" == "$ARCH_SIM" ]; then ## INTEL ##

# Use default environment
export CC=$U_CC
export CFLAGS="$COMMON_SIM_CFLAGS -arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="$U_LDFLAGS" #export LDFLAGS="$COMMON_SIM_LDFLAGS -arch $ARCH_SIM"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

echo "[|- CONFIG $ARCH_SIM]"
./configure prefix=$JPEG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared \
--enable-static --host=i686-apple-darwin10 &>$OUTPUT_FILE

echo "[|- CC $ARCH_SIM]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.$ARCH_SIM
cp $JPEG_LIB_DIR/lib/libjpeg.dylib $LIB_DIR/jpeg_${ARCH_SIM}_dylib/libjpeg.dylib
# cp the include/* files
cp $JPEG_LIB_DIR/include/*.h $LIB_DIR/include/jpeg/

echo "[|- CLEAN $ARCH_SIM]"
make distclean &>$OUTPUT_FILE

# combine the static libraries for i386 and arm
echo "[|- COMBINE $ARCH_IPHONE $ARCH_IPHONE6 $ARCH_SIM]"
$DEVROOT/usr/bin/lipo -arch $ARCH_IPHONE $LIB_DIR/$LIBNAME_jpeg.$ARCH_IPHONE \
	-arch $ARCH_IPHONE6 $LIB_DIR/$LIBNAME_jpeg.$ARCH_IPHONE6 \
	-arch $ARCH_SIM $LIB_DIR/$LIBNAME_jpeg.$ARCH_SIM -create -output $LIB_DIR/$LIBNAME_jpeg

fi

echo "[+ DONE: $1]"

} ## END JPEG LIBRARY ##

###################################
#############    TIFF    ##########
###################################

function tiff() {

echo ""
echo "[+ TIFF: $1]"
cd $TIFF_DIR

LIBPATH_tiff=libtiff.a
LIBNAME_tiff=`basename $LIBPATH_tiff`

if [ "$1" == "$IPHONE" ]; then ##  ARM	 ##

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS"

echo "[|- CONFIG $ARCH_IPHONE]"
./configure prefix=$TIFF_LIB_DIR CC=$DEVROOT/usr/bin/clang \
LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin --disable-cxx &>$OUTPUT_FILE

echo "[|- CC $ARCH_IPHONE]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static + shared library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.$ARCH_IPHONE
cp $TIFF_LIB_DIR/lib/libtiff.3.dylib $LIB_DIR/tiff_${ARCH_IPHONE}_dylib/libtiff.dylib

echo "[|- CLEAN $ARCH_IPHONE]"
make distclean &>$OUTPUT_FILE

## ARMV6 ##
export CFLAGS="$COMMON_IPHONE6_CFLAGS"

echo "[|- CONFIG $ARCH_IPHONE6]"
./configure prefix=$TIFF_LIB_DIR CC=$DEVROOT/usr/bin/clang \
LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin --disable-cxx &>$OUTPUT_FILE

echo "[|- CC $ARCH_IPHONE6]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static + shared library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.$ARCH_IPHONE6
cp $TIFF_LIB_DIR/lib/libtiff.3.dylib $LIB_DIR/tiff_${ARCH_IPHONE6}_dylib/libtiff.dylib

echo "[|- CLEAN $ARCH_IPHONE6]"
make distclean &>$OUTPUT_FILE

elif [ "$1" == "$ARCH_SIM" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export CFLAGS="$COMMON_SIM_CFLAGS -arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="$U_LDFLAGS" #export LDFLAGS="$COMMON_SIM_LDFLAGS $U_LDFLAGS"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

echo "[|- CONFIG $ARCH_SIM]"
./configure prefix=$TIFF_LIB_DIR CC=$DEVROOT/usr/bin/clang --host=i686-apple-darwin10 \
--disable-cxx &>$OUTPUT_FILE

echo "[|- CC $ARCH_SIM]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# cp the static library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.$ARCH_SIM
cp $TIFF_LIB_DIR/lib/libtiff.3.dylib $LIB_DIR/tiff_${ARCH_SIM}_dylib/libtiff.dylib

# cp the include/* files
cp $TIFF_LIB_DIR/include/*.h $LIB_DIR/include/tiff/

echo "[|- CLEAN $ARCH_SIM]"
make distclean &>$OUTPUT_FILE

# combine the static libraries for i386 and arm
echo "[|- COMBINE $ARCH_IPHONE $ARCH_IPHONE6 $ARCH_SIM]"
$DEVROOT/usr/bin/lipo -arch $ARCH_IPHONE $LIB_DIR/$LIBNAME_tiff.$ARCH_IPHONE \
	-arch $ARCH_IPHONE6 $LIB_DIR/$LIBNAME_tiff.$ARCH_IPHONE6 \
	-arch $ARCH_SIM $LIB_DIR/$LIBNAME_tiff.$ARCH_SIM -create -output $LIB_DIR/$LIBNAME_tiff

fi

echo "[+ DONE $1]"

} ## END TIFF LIBRARY ##

###################################
############    IMAGEMAGICK    ####
###################################

function im() {

echo ""
echo "[+ IM: $1]"
cd $IM_DIR

# static library that will be generated
LIBPATH_static=$IM_LIB_DIR/lib/libMagickCore.a
LIBNAME_static=`basename $LIBPATH_static`
LIBPATH_static2=$IM_LIB_DIR/lib/libMagickWand.a
LIBNAME_static2=`basename $LIBPATH_static2`

if [ "$1" == "$IPHONE" ]; then ##  ARM	 ##

# Save relevant environment
U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$IM_LDFLAGS $COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS $IM_IFLAGS -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export CXXFLAGS="-Wall -W -D_THREAD_SAFE -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"

# configure to have the static libraries
echo "[|- CONFIG $ARCH_IPHONE]"
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld \
--host=arm-apple-darwin --disable-largefile --with-quantum-depth=8 --without-magick-plus-plus \
--without-perl --without-x --disable-shared --disable-openmp --without-bzlib --without-freetype &>$OUTPUT_FILE

# compile ImageMagick
echo "[|- CC $ARCH_IPHONE]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# copy the CORE + WAND libraries -- ARM version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.$ARCH_IPHONE
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.$ARCH_IPHONE

# clean the ImageMagick build
echo "[| CLEAN $ARCH_IPHONE]"
make distclean &>$OUTPUT_FILE

## ARMV6 ##
export CFLAGS="$COMMON_IPHONE6_CFLAGS $IM_IFLAGS -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export LDFLAGS="$IM_LDFLAGS6 $COMMON_IPHONE_LDFLAGS"

# configure to have the static libraries
echo "[|- CONFIG $ARCH_IPHONE6]"
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld \
--host=arm-apple-darwin --disable-largefile --with-quantum-depth=8 --without-magick-plus-plus \
--without-perl --without-x --disable-shared --disable-openmp --without-bzlib --without-freetype &>$OUTPUT_FILE

# compile ImageMagick
echo "[|- CC $ARCH_IPHONE6]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# copy the CORE + WAND libraries -- ARM version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.$ARCH_IPHONE6
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.$ARCH_IPHONE6

# copy the wand/ + core/ headers
cp $IM_LIB_DIR/include/ImageMagick/magick/* $LIB_DIR/include/magick/
cp $IM_LIB_DIR/include/ImageMagick/wand/* $LIB_DIR/include/wand/

# copy configuration files needed for certain functions
cp $IM_LIB_DIR/etc/ImageMagick/*.xml $LIB_DIR/include/im_config/
cp $IM_LIB_DIR/share/ImageMagick-*/*.xml $LIB_DIR/include/im_config/

# clean the ImageMagick build
echo "[|- CLEAN $ARCH_IPHONE6]"
#make distclean &>$OUTPUT_FILE

elif [ "$1" == "$ARCH_SIM" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export LDFLAGS="-isysroot $MACOSXROOT -mmacosx-version-min=10.6 $IM_LDFLAGS_SIM"
export CFLAGS="-arch $ARCH_SIM -isysroot $MACOSXROOT -mmacosx-version-min=10.6 $IM_IFLAGS -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export LD=$U_LD
export CPP=$U_CPP
export CPPFLAGS="$U_CPPFLAGS $U_LDFLAGS $IM_IFLAGS -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"

# configure with standard parameters
echo "[|- CONFIG $ARCH_SIM]"
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang --host=i686-apple-darwin10 \
--disable-largefile --with-quantum-depth=8 --without-magick-plus-plus --without-perl --without-x \
--disable-shared --disable-openmp --without-bzlib --without-freetype --without-threads &>$OUTPUT_FILE

# compile ImageMagick
echo "[|- CC $ARCH_SIM]"
make -j2 &>$OUTPUT_FILE
make install &>$OUTPUT_FILE

# copy the CORE + WAND libraries -- INTEL version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.$ARCH_SIM
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.$ARCH_SIM

# clean the ImageMagick build
echo "[|- CLEAN $ARCH_SIM]"
make distclean &>$OUTPUT_FILE

# combine the two generated libraries to be used both in the simulator and in the device
echo "[|- COMBINE (libMagickCore) $ARCH_IPHONE $ARCH_IPHONE6 $ARCH_SIM]"
$DEVROOT/usr/bin/lipo -arch $ARCH_IPHONE $LIB_DIR/$LIBNAME_static.$ARCH_IPHONE \
	-arch $ARCH_IPHONE6 $LIB_DIR/$LIBNAME_static.$ARCH_IPHONE6 \
	-arch $ARCH_SIM $LIB_DIR/$LIBNAME_static.$ARCH_SIM -create -output $LIB_DIR/$LIBNAME_static

echo "[|- COMBINE (libMagickWand) $ARCH_IPHONE $ARCH_IPHONE6 $ARCH_SIM]"	
$DEVROOT/usr/bin/lipo -arch $ARCH_IPHONE $LIB_DIR/$LIBNAME_static2.$ARCH_IPHONE \
	-arch $ARCH_IPHONE6 $LIB_DIR/$LIBNAME_static2.$ARCH_IPHONE6 \
	-arch $ARCH_SIM $LIB_DIR/$LIBNAME_static2.$ARCH_SIM -create -output $LIB_DIR/$LIBNAME_static2

fi

echo "[+ DONE: IM]"

} ## END IMAGEMAGICK LIBRARY ##

function structure_for_xcode() {
	echo ""
	echo "[+ XCODE]"
	if [ -e $FINAL_DIR ]; then
		echo "[|- RM $FINAL_DIR]"
		rm -rf "$FINAL_DIR"*
	else
		echo "[|- MKDIR: $FINAL_DIR]"
		mkdir -p "$FINAL_DIR"
	fi
	echo "[|- CP]"
	cp -r ${LIB_DIR}/include/ ${FINAL_DIR}include/
	cp $LIB_DIR/*.a "$FINAL_DIR"
	echo "[+ DONE: XCODE]"
}

# function used to produce .zips for the ImageMagick ftp site maintained by me (Claudio Marforio)
function zip_for_ftp() {
	echo ""
	echo "[+ ZIP]"
	if [ -e $FINAL_DIR ]; then
		tmp_dir="$(pwd)/TMP_IM"
		cp -R $FINAL_DIR $tmp_dir
		ditto -c -k -rsrc "$tmp_dir" "iPhoneMagick-${IM_VERSION}-libs.zip" && echo "[|- CREATED W/ libs]"
		rm $tmp_dir/libjpeg.a $tmp_dir/libpng.a $tmp_dir/libtiff.a
		rm -rf $tmp_dir/include/jpeg/ $tmp_dir/include/png/ $tmp_dir/include/tiff/
		ditto -c -k -rsrc "$tmp_dir" "iPhoneMagick-${IM_VERSION}.zip" && echo "[|- CREATED W/O libs]"
		rm -rf $tmp_dir
	else
		echo "[* ERROR, $FINAL_DIR not present..."
	fi
	echo "[+ DONE: ZIP]"
}

png "$IPHONE"
png "$ARCH_SIM" 
jpeg "$IPHONE"
jpeg "$ARCH_SIM"
tiff "$IPHONE"
tiff "$ARCH_SIM"
im "$IPHONE"
im "$ARCH_SIM"
structure_for_xcode
#zip_for_ftp # used only by me (Claudio Marforio) to upload to the IM ftp :)
