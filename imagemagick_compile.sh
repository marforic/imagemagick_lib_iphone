# Author: Claudio Marforio
# e-mail: marforio@gmail.com
# date: 9.06.2009

# Script to make static libraries (jpeg + png) and ImageMagick
# the libraries will be conbined into i386+arm.a static libraries
#	to be used inside an XCODE project for iPhone development

# The directory structure has to be:
# ~/Desktop/cross_compile/i_m/	 <- ImageMagick top directory
#	 |-IMDelegataes/	 <- Some delegates, in particular jpeg + png
#	 |-jpeg-6b/	 <- Patched jpeg6b
#	 |-libpng-1.2.37 <- png lib -- no need to patch it
#	 |-tiff-3.8.2	<- tiff lib -- no need to patch it
#	 |-…	 <- we don't care what's here! :)

# If you don't have this Directory structure you can either create it or try change around the script

#!/bin/bash

# Set this to the top directory of ImageMagick source:
IM_DIR=$(pwd)/cross_compile/i_m
JPEG_DIR=$IM_DIR/IMDelegates/jpeg-6b
PNG_DIR=$IM_DIR/IMDelegates/libpng-1.4.0
TIFF_DIR=$IM_DIR/IMDelegates/tiff-3.9.2
#ARCH_SIM="i386"
ARCH_SIM="i386"
GCC_VERSION="4.0.1"

# Set this to where you want the libraries to be placed (if dir is not present it will be created):
TARGET_LIB_DIR=$(pwd)/tmp_target
LIB_DIR=$TARGET_LIB_DIR/im_libs
JPEG_LIB_DIR=$TARGET_LIB_DIR/libjpeg
PNG_LIB_DIR=$TARGET_LIB_DIR/libpng
TIFF_LIB_DIR=$TARGET_LIB_DIR/libtiff
IM_LIB_DIR=$TARGET_LIB_DIR/imagemagick

# Set the build directories
mkdir -p $TARGET_LIB_DIR
mkdir -p $LIB_DIR/include/jpeg
mkdir -p $LIB_DIR/include/magick
mkdir -p $LIB_DIR/include/png
mkdir -p $LIB_DIR/include/tiff
mkdir -p $LIB_DIR/include/wand
mkdir -p $LIB_DIR/jpeg_arm_dylib
mkdir -p $LIB_DIR/png_arm_dylib
mkdir -p $LIB_DIR/tiff_arm_dylib
mkdir -p $JPEG_LIB_DIR/lib #we don't need bin/ and share/
mkdir -p $JPEG_LIB_DIR/include
mkdir -p $PNG_LIB_DIR #libpng manages to create subdirectories by itself with make install
mkdir -p $TIFF_LIB_DIR #libtiff manages to create subdirectories by itself with make install

# General folders where you have the iPhone compiler + tools
export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
# Change this to match for which version of the SDK you want to compile -- you can change the number for the version
export SDKROOT=$DEVROOT/SDKs/iPhoneOS3.1.sdk
export MACOSXROOT=/Developer/SDKs/MacOSX10.5.sdk

############	HACK	#################################
# ImageMagick requires this header, that doesn't exist for the iPhone
# Just copying it make things compile/work (more testing needed)
#sudo cp /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.1.3.sdk/usr/include/crt_externs.h \
#	$SDKROOT/usr/include/crt_externs.h
############	END -- HACK	#############################

function png()
{
#######################################################
############	PNG	 ###########################
#######################################################

cd $PNG_DIR

LIBPATH_png=libpng14.a
LIBPATH_png_dylib=libpng14.14.dylib

#######################################################
############	ARM	 ###########################
#######################################################

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin9/$GCC_VERSION/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -I$SDKROOT/usr/include -L$SDKROOT/usr/lib/ -O3"
export CPP="/usr/bin/cpp $CPPFLAGS"
export LDFLAGS="-L$SDKROOT/usr/lib/"

./configure prefix=$PNG_LIB_DIR --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/arm-apple-darwin9-gcc-$GCC_VERSION LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin

make
make install

# cp the static + shared library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.arm
cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_arm_dylib/libpng.dylib

make distclean

#######################################################
############	INTEL	 ###########################
#######################################################

# Use default environment
export CC=$U_CC
export CFLAGS="-arch $ARCH_SIM -O3"
export LD=$U_LD
export LDFLAGS="-L/usr/lib/ $U_LDFLAGS"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

./configure prefix=$PNG_LIB_DIR --enable-shared --enable-static --host=i686-apple-darwin9

make
make install

# cp the static library
cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.i386
# cp the include/* files
cp $PNG_LIB_DIR/include/libpng14/* $LIB_DIR/include/png/

make distclean

# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/libpng.a.arm -arch $ARCH_SIM $LIB_DIR/libpng.a.i386 -create -output $LIB_DIR/libpng.a
}
function jpeg()
{
#######################################################
############	JPEG	 ###########################
#######################################################

cd $JPEG_DIR

LIBPATH_jpeg=libjpeg.a
LIBNAME_jpeg=`basename $LIBPATH_jpeg`

#######################################################
############	ARM	 ###########################
#######################################################

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin9/$GCC_VERSION/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -I$SDKROOT/usr/include -L$SDKROOT/usr/lib/ -O3"
export CPP="/usr/bin/cpp $CPPFLAGS"
export LDFLAGS="-L$SDKROOT/usr/lib/"

./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static \
CC=$DEVROOT/usr/bin/arm-apple-darwin9-gcc-$GCC_VERSION LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin

make
make install-lib

# cp the static + shared library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.arm
cp $JPEG_LIB_DIR/lib/libjpeg.62.0.0.dylib $LIB_DIR/jpeg_arm_dylib/libjpeg.dylib

make distclean

#######################################################
############	INTEL	 ###########################
#######################################################

# Use default environment
export CC=$U_CC
export CFLAGS="-arch $ARCH_SIM -O3"
export LD=$U_LD
export LDFLAGS="-L/usr/lib/ -arch $ARCH_SIM -03" # just needed if at some point simulator will be x86_64
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static --host=i686-apple-darwin9

make
make install-lib

# cp the static library
cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.i386
# cp the include/* files
cp $JPEG_LIB_DIR/include/*.h $LIB_DIR/include/jpeg/

make distclean

# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_jpeg.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_jpeg.i386 -create -output $LIB_DIR/$LIBNAME_jpeg
}
function tiff()
{
########################################################
#############	TIFF	 ############################
########################################################

cd $TIFF_DIR

LIBPATH_tiff=libtiff.a
LIBNAME_tiff=`basename $LIBPATH_tiff`

if [ "$1" == "arm" ]; then
#######################################################
############	ARM	 ###########################
#######################################################

U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin9/$GCC_VERSION/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -I$SDKROOT/usr/include -L$SDKROOT/usr/lib/ -O3"
export CPP="/usr/bin/cpp $CPPFLAGS"
export LDFLAGS="-L$SDKROOT/usr/lib/"

./configure prefix=$TIFF_LIB_DIR CC=$DEVROOT/usr/bin/arm-apple-darwin9-gcc-$GCC_VERSION \
LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin --disable-cxx \
&& make \
&& make install

# cp the static + shared library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.arm
cp $TIFF_LIB_DIR/lib/libtiff.3.dylib $LIB_DIR/tiff_arm_dylib/libtiff.dylib

make distclean
elif [ "$1" == "$ARCH_SIM" ]; then
#######################################################
############	INTEL	 ###########################
#######################################################

# Use default environment
export CC=$U_CC
export CFLAGS="-arch $ARCH_SIM"
export LD=$U_LD
export LDFLAGS="-L/usr/lib/ $U_LDFLAGS"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

./configure prefix=$TIFF_LIB_DIR --host=i686-apple-darwin9 --disable-cxx \
&& make \
&& make install

# cp the static library
cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.i386
# cp the include/* files
cp $TIFF_LIB_DIR/include/*.h $LIB_DIR/include/tiff/

make distclean

# combine the static libraries for i386 and arm
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_tiff.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_tiff.i386 -create -output $LIB_DIR/$LIBNAME_tiff
fi
}
function im()
{
#######################################################
############	IMAGEMAGICK	 #######################
#######################################################
cd $IM_DIR

# static library that will be generated
LIBPATH_static=$IM_LIB_DIR/lib/libMagickCore.a
LIBNAME_static=`basename $LIBPATH_static`
LIBPATH_static2=$IM_LIB_DIR/lib/libMagickWand.a
LIBNAME_static2=`basename $LIBPATH_static2`

#######################################################
############	ARM	 ###########################
#######################################################

# Save relevant environment
U_CC=$CC
U_CFLAGS=$CFLAGS
U_LD=$LD
U_LDFLAGS=$LDFLAGS
U_CPP=$CPP
U_CPPFLAGS=$CPPFLAGS

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin9/$GCC_VERSION/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -arch armv6 -pipe -no-cpp-precomp -isysroot $SDKROOT -I$SDKROOT/usr/include -I$LIB_DIR/include -O3"
export LDFLAGS="-L$LIB_DIR/jpeg_arm_dylib/ -L$LIB_DIR/png_arm_dylib/ -L$LIB_DIR/tiff_arm_dylib/ -L$SDKROOT/usr/lib/"
export CPP="/usr/bin/cpp $CPPFLAGS"
export CXXFLAGS="-O3 -Wall -W -D_THREAD_SAFE"

# configure to have the static libraries and make
./configure prefix=$IM_LIB_DIR CC=$DEVROOT/usr/bin/arm-apple-darwin9-gcc-$GCC_VERSION LD=$DEVROOT/usr/bin/ld --host=arm-apple-darwin \
--disable-largefile --with-quantum-depth=8 --without-magick-plus-plus --without-perl --without-x --without-freetype \
--disable-shared

# compile ImageMagick
make
make install

# copy the CORE + WAND libraries -- ARM version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.arm
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.arm

# clean the ImageMagick build
make distclean

#######################################################
############	INTEL	 ###########################
#######################################################

# Use default environment
export CC=$U_CC
export CFLAGS="-arch $ARCH_SIM -O3 -isysroot $MACOSXROOT -mmacosx-version-min=10.5"
export LD=$U_LD
export LDFLAGS="$U_LDFLAGS -isysroot $MACOSXROOT -mmacosx-version-min=10.5"
export CPP=$U_CPP
export CPPFLAGS=$U_CPPFLAGS

# configure with standard parameters
./configure prefix=$IM_LIB_DIR --host=i686-apple-darwin9 --without-magick-plus-plus --without-perl --without-x --without-freetype --disable-shared

# compile ImageMagick
make
make install

# copy the CORE + WAND libraries -- INTEL version
cp $LIBPATH_static $LIB_DIR/$LIBNAME_static.i386
cp $LIBPATH_static2 $LIB_DIR/$LIBNAME_static2.i386

# copy the wand/ + core/ headers
cp $IM_LIB_DIR/include/ImageMagick/magick/* $LIB_DIR/include/magick/
cp $IM_LIB_DIR/include/ImageMagick/wand/* $LIB_DIR/include/wand/

# clean the ImageMagick build
make distclean

# combine the two generated libraries to be used both in the simulator and in the device
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_static.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_static.i386 -create -output $LIB_DIR/$LIBNAME_static
$DEVROOT/usr/bin/lipo -arch arm $LIB_DIR/$LIBNAME_static2.arm -arch $ARCH_SIM $LIB_DIR/$LIBNAME_static2.i386 -create -output $LIB_DIR/$LIBNAME_static2
}

png
jpeg
tiff "arm"
tiff "$ARCH_SIM"
im