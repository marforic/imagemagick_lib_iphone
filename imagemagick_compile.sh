#!/bin/bash

# Author: Claudio Marforio
# e-mail: marforio@gmail.com
# date: 12.12.2010

# Script to make static libraries (jpeg + png + tiff) and ImageMagick
# the libraries will be conbined into i386+arm.a static libraries
#	to be used inside an XCODE project for iPhone development

# The directory structure has to be:
# ~/Desktop/cross_compile/ImageMagick-VERSION/	 <- ImageMagick top directory
#	            |        /IMDelegataes/	 <- Some delegates, in particular jpeg + png + tiff
#	            |           |-jpeg-6b/          <- Patched jpeg6b
#	            |           |-libpng-1.4.2     <- png lib -- no need to patch it
#	            |           |-tiff-3.9.2        <- tiff lib -- no need to patch it
#	            |- ...	 <- we don't care what's here! :)

# If you don't have this directory structure you can either create it or try change around the script

# If everything works correctly you will end up with a folder
# on your ~/Desktop ready to be imported into XCode
# change this line if you want for everything to be
# exported somewhere else

FINAL_DIR=~/Desktop/IMPORT_ME/

if [[ $# != 1 ]]; then
	echo "imagemagick_compile.sh takes 1 argument: the version of ImageMagick that you want to compile!"
	echo "USAGE: imagemagick_compile.sh 6.6.6-4"
	exit
fi

IM_VERSION="$1"
IM_DIR="/Users/$USER/Desktop/cross_compile/ImageMagick-$IM_VERSION"
IM_DELEGATES_DIR="$IM_DIR/IMDelegates/"

if [ -d $IM_DELEGATES_DIR ]; then
	echo "IMDelegates folder present in: $IM_DELEGATES_DIR"
else
	echo "IMDelegates folder not found, copying over"
	cp -r "/Users/$USER/Desktop/cross_compile/IMDelegates" "$IM_DIR/IMDelegates"
fi

JPEG_DIR="$IM_DIR/IMDelegates/jpeg-6b"
PNG_DIR="$IM_DIR/IMDelegates/libpng-1.4.3"
TIFF_DIR="$IM_DIR/IMDelegates/tiff-3.8.2"

# Architectures and versions
ARCH_SIM="i386"
ARCH_IPHONE="armv6"
GCC_VERSION="4.2.1"
MIN_IPHONE_VERSION="3.1"
IPHONE_SDK_VERSION="4.2"
MACOSX_SDK_VERSION="10.5"

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
mkdir -p $LIB_DIR/jpeg_arm_dylib
mkdir -p $LIB_DIR/jpeg_i386_dylib
mkdir -p $LIB_DIR/png_arm_dylib
mkdir -p $LIB_DIR/png_i386_dylib
mkdir -p $LIB_DIR/tiff_arm_dylib
mkdir -p $LIB_DIR/tiff_i386_dylib
mkdir -p $JPEG_LIB_DIR/lib # we don't need bin/ and share/
mkdir -p $JPEG_LIB_DIR/include
mkdir -p $PNG_LIB_DIR # libpng manages to create subdirectories by itself with make install
mkdir -p $TIFF_LIB_DIR # libtiff manages to create subdirectories by itself with make install

# General folders where you have the iPhone compiler + tools
export DEVROOT="/Developer/Platforms/iPhoneOS.platform/Developer"
# Change this to match for which version of the SDK you want to compile -- you can change the number for the version
export SDKROOT="${DEVROOT}/SDKs/iPhoneOS${IPHONE_SDK_VERSION}.sdk"
export MACOSXROOT="/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDK_VERSION}.sdk"

# Compiler flags and config arguments - IPHONE
COMMON_IPHONE_LDFLAGS="-L$SDKROOT/usr/lib/"
COMMON_IPHONE_CFLAGS="-arch $ARCH_IPHONE -miphoneos-version-min=$MIN_IPHONE_VERSION -pipe -Os -isysroot $SDKROOT \
-I$SDKROOT/usr/include -I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/$GCC_VERSION/include/"

COMMON_SIM_LDFLAGS="-L$MACOSXROOT/usr/lib"
COMMON_SIM_CFLAGS="-I$MACOSXROOT/usr/include -I$MACOSXROOT/usr/lib/gcc/i686-apple-darwin10/$GCC_VERSION/include/"

IM_LDFLAGS="-L$LIB_DIR/jpeg_arm_dylib/ -L$LIB_DIR/png_arm_dylib/ -L$LIB_DIR/tiff_arm_dylib/ -L$LIB_DIR"
IM_LDFLAGS_SIM="-L$LIB_DIR/jpeg_i386_dylib/ -L$LIB_DIR/png_i386_dylib/ -L$LIB_DIR/tiff_i386_dylib/ -L$LIB_DIR"
IM_IFLAGS="$COMMON_SIM_CFLAGS -I$LIB_DIR/include/jpeg -I$LIB_DIR/include/png -I$LIB_DIR/include/tiff"

############    HACK    ############
# ImageMagick requires this header, that doesn't exist for the iPhone
# Just copying it make things compile/work
if [ -e $SDKROOT/usr/include/crt_externs.h ]; then
	echo "crt_externals.h already copied! Good to go!";
else
	echo "need to copy crt_externals.h for compilation, please enter sudo password"
	sudo cp "/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IPHONE_SDK_VERSION.sdk/usr/include/crt_externs.h" \
		"$SDKROOT/usr/include/crt_externs.h"
fi
############    END     ############

###################################
############    PNG    ############
###################################

function png() {

cd $PNG_DIR

LIBPATH_png=libpng14.a
LIBPATH_png_dylib=libpng14.dylib

if [ "$1" == "$ARCH_IPHONE" ]; then ##  ARM	 ##

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS"

./configure prefix=$PNG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin

make -j2
make install

# cp the static + shared library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.arm
cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_arm_dylib/libpng.dylib

make distclean

elif [ "$1" == "$ARCH_SIM" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export CFLAGS="$COMMON_SIM_CFLAGS -arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="$COMMON_SIM_LDFLAGS $U_LDFLAGS"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

./configure prefix=$PNG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared --enable-static --host=i686-apple-darwin10

make -j2
make install

# cp the static library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.i386
cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_i386_dylib/libpng.dylib
# cp the include/* files
cp $PNG_LIB_DIR/include/libpng14/* $LIB_DIR/include/png/

make distclean

# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/libpng.a.arm -arch $ARCH_SIM $LIB_DIR/libpng.a.i386 -create -output $LIB_DIR/libpng.a

fi

} ## END PNG LIBRARY ##

############################################
################    JPEG    ################
############################################

function jpeg() {

cd $JPEG_DIR

LIBPATH_jpeg=libjpeg.a
LIBNAME_jpeg=`basename $LIBPATH_jpeg`

if [ "$1" == "$ARCH_IPHONE" ]; then ##  ARM	 ##

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS"

./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin

make -j2
make install-lib

# cp the static + shared library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.arm
cp $JPEG_LIB_DIR/lib/libjpeg.62.0.0.dylib $LIB_DIR/jpeg_arm_dylib/libjpeg.dylib

make distclean

elif [ "$1" == "$ARCH_SIM" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export CFLAGS="$COMMON_SIM_CFLAGS -arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="$COMMON_SIM_LDFLAGS -arch $ARCH_SIM"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

./configure prefix=$JPEG_LIB_DIR CC=$DEVROOT/usr/bin/clang --enable-shared --enable-static --host=i686-apple-darwin10

make -j2
make install-lib

# cp the static library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.i386
cp $JPEG_LIB_DIR/lib/libjpeg.62.0.0.dylib $LIB_DIR/jpeg_i386_dylib/libjpeg.dylib
# cp the include/* files
cp $JPEG_LIB_DIR/include/*.h $LIB_DIR/include/jpeg/

make distclean

# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_jpeg.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_jpeg.i386 -create -output $LIB_DIR/$LIBNAME_jpeg

fi

} ## END JPEG LIBRARY ##

######################################
#############    TIFF    #############
######################################

function tiff() {

cd $TIFF_DIR

LIBPATH_tiff=libtiff.a
LIBNAME_tiff=`basename $LIBPATH_tiff`

if [ "$1" == "$ARCH_IPHONE" ]; then ##  ARM	 ##

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export LDFLAGS="$COMMON_IPHONE_LDFLAGS"
export CFLAGS="$COMMON_IPHONE_CFLAGS"

./configure prefix=$TIFF_LIB_DIR CC=$DEVROOT/usr/bin/clang \
LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin --disable-cxx \
&& make -j2 \
&& make install

# cp the static + shared library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.arm
cp $TIFF_LIB_DIR/lib/libtiff.3.dylib $LIB_DIR/tiff_arm_dylib/libtiff.dylib

make distclean

elif [ "$1" == "$ARCH_SIM" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export CFLAGS="$COMMON_SIM_CFLAGS -arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="$COMMON_SIM_LDFLAGS $U_LDFLAGS"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

./configure prefix=$TIFF_LIB_DIR CC=$DEVROOT/usr/bin/clang --host=i686-apple-darwin10 --disable-cxx \
&& make -j2 \
&& make install

# cp the static library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.i386
cp $TIFF_LIB_DIR/lib/libtiff.3.dylib $LIB_DIR/tiff_i386_dylib/libtiff.dylib

# cp the include/* files
cp $TIFF_LIB_DIR/include/*.h $LIB_DIR/include/tiff/

make distclean

# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_tiff.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_tiff.i386 -create -output $LIB_DIR/$LIBNAME_tiff

fi

} ## END TIFF LIBRARY ##

###########################################
############    IMAGEMAGICK    ############
###########################################

function im() {

cd $IM_DIR

# static library that will be generated
LIBPATH_static=$IM_LIB_DIR/lib/libMagickCore.a
LIBNAME_static=`basename $LIBPATH_static`
LIBPATH_static2=$IM_LIB_DIR/lib/libMagickWand.a
LIBNAME_static2=`basename $LIBPATH_static2`

if [ "$1" == "$ARCH_IPHONE" ]; then ##  ARM	 ##

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

# configure to have the static libraries and make
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin \
--disable-largefile --with-quantum-depth=8 --without-magick-plus-plus --without-perl --without-x \
--disable-shared --disable-openmp --without-bzlib --without-freetype

# compile ImageMagick
make -j2
make install

# copy the CORE + WAND libraries -- ARM version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.arm
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.arm

# clean the ImageMagick build
make distclean

elif [ "$1" == "$ARCH_SIM" ]; then ##  INTEL  ##

# Use default environment
export CC=$U_CC
export LDFLAGS="-isysroot $MACOSXROOT -mmacosx-version-min=10.5 $IM_LDFLAGS_SIM"
export CFLAGS="-arch $ARCH_SIM -isysroot $MACOSXROOT -mmacosx-version-min=10.5 $IM_IFLAGS -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"
export LD=$U_LD
export CPP=$U_CPP
export CPPFLAGS="$U_CPPFLAGS $U_LDFLAGS $IM_IFLAGS -DHAVE_J1=0 -DTARGET_OS_IPHONE -DMAGICKCORE_WORDS_BIGENDIAN"

# configure with standard parameters
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/clang --host=i686-apple-darwin10 \
--disable-largefile --with-quantum-depth=8 --without-magick-plus-plus --without-perl --without-x \
--disable-shared --disable-openmp --without-bzlib --without-freetype --without-threads

# compile ImageMagick
make -j2
make install

# copy the CORE + WAND libraries -- INTEL version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.i386
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.i386

# copy the wand/ + core/ headers
cp $IM_LIB_DIR/include/ImageMagick/magick/* $LIB_DIR/include/magick/
cp $IM_LIB_DIR/include/ImageMagick/wand/* $LIB_DIR/include/wand/

# copy configuration files needed for certain functions
cp $IM_LIB_DIR/lib/ImageMagick-*/config/*.xml $LIB_DIR/include/im_config/
cp $IM_LIB_DIR/share/ImageMagick-*/config/*.xml $LIB_DIR/include/im_config/
cp $IM_LIB_DIR/share/ImageMagick-*/config/*.icm $LIB_DIR/include/im_config/

# clean the ImageMagick build
make distclean

# combine the two generated libraries to be used both in the simulator and in the device
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_static.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_static.i386 -create -output $LIB_DIR/$LIBNAME_static
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_static2.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_static2.i386 -create -output $LIB_DIR/$LIBNAME_static2

fi

} ## END IMAGEMAGICK LIBRARY ##

function structure_for_xcode() {
	echo "-------------- Making everything ready to import! --------------"
	if [ -e $FINAL_DIR ]; then
		echo "Directory $FINAL_DIR is already present"
		rm -rf "$FINAL_DIR"*
	else
		echo "Creating directory for importing into XCode: $FINAL_DIR"
		mkdir -p "$FINAL_DIR"
	fi
	cp -r $LIB_DIR/include/ "$FINAL_DIR"include/
	cp $LIB_DIR/*.a "$FINAL_DIR"
	# echo "-------------- Removing tmp_target dir --------------"
	# 	rm -rf $TARGET_LIB_DIR
	echo "-------------- All Done! --------------"
}

# function used to produce .zips for the ImageMagick ftp site maintained by me (Claudio Marforio)
function zip_for_ftp() {
	echo "-------------- Preparing .zips for ftp.imagemagick.org! --------------"
	if [ -e $FINAL_DIR ]; then
		tmp_dir="/Users/$USER/Desktop/TMP_IM"
		cp -R $FINAL_DIR $tmp_dir
		ditto -c -k -rsrc "$tmp_dir" "iPhoneMagick-$IM_VERSION-libs.zip" && echo "-libs zip created" # creates -libs zip
		rm $tmp_dir/libjpeg.a $tmp_dir/libpng.a $tmp_dir/libtiff.a
		rm -rf $tmp_dir/include/jpeg/ $tmp_dir/include/png/ $tmp_dir/include/tiff/
		ditto -c -k -rsrc "$tmp_dir" "iPhoneMagick-$IM_VERSION.zip" && echo "im_only zip created" # creates im_only zip
		rm -rf $tmp_dir
	else
		echo "ERROR, $FINAL_DIR not present..."
	fi
	echo "-------------- All Done! --------------"
}

png "$ARCH_IPHONE"
png "$ARCH_SIM"
jpeg "$ARCH_IPHONE"
jpeg "$ARCH_SIM"
tiff "$ARCH_IPHONE"
tiff "$ARCH_SIM"
im "$ARCH_IPHONE"
im "$ARCH_SIM"
structure_for_xcode
#zip_for_ftp
