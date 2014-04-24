#!/bin/bash

im_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
	cp $LIBPATH_core $LIB_DIR/$LIBNAME_core.$BUILDINGFOR
	cp $LIBPATH_wand $LIB_DIR/$LIBNAME_wand.$BUILDINGFOR
	if [[ "$BUILDINGFOR" == "armv7s" ]]; then  # copy include and config files
		# copy the wand/ + core/ headers
		cp -r $IM_LIB_DIR/include/ImageMagick-*/magick/ $LIB_DIR/include/magick/
		cp -r $IM_LIB_DIR/include/ImageMagick-*/wand/ $LIB_DIR/include/wand/

		# copy configuration files needed for certain functions
		cp -r $IM_LIB_DIR/etc/ImageMagick-*/ $LIB_DIR/include/im_config/
		cp -r $IM_LIB_DIR/share/ImageMagick-*/ $LIB_DIR/include/im_config/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

im () {
	echo "[+ IM: $1]"
	cd $IM_DIR
	
	# static library that will be generated
	LIBPATH_core=$IM_LIB_DIR/lib/libMagickCore-6.Q8.a
	LIBNAME_core=`basename $LIBPATH_core`
	LIBPATH_wand=$IM_LIB_DIR/lib/libMagickWand-6.Q8.a
	LIBNAME_wand=`basename $LIBPATH_wand`
	
	if [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags $1
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		export CPPFLAGS="-I$LIB_DIR/include/jpeg -I$LIB_DIR/include/png -I$LIB_DIR/include/tiff"
		export LDFLAGS="$LDFLAGS -L$LIB_DIR/jpeg_${BUILDINGFOR}_dylib/ -L$LIB_DIR/png_${BUILDINGFOR}_dylib/ -L$LIB_DIR/tiff_${BUILDINGFOR}_dylib/ -L$LIB_DIR"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=$IM_LIB_DIR --host=arm-apple-darwin --disable-opencl --disable-largefile --with-quantum-depth=8 --without-magick-plus-plus \
				--without-perl --without-x --disable-shared --disable-openmp --without-bzlib --without-freetype
		im_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags $1
		export CPPFLAGS="$CPPFLAGS -I$LIB_DIR/include/jpeg -I$LIB_DIR/include/png -I$LIB_DIR/include/tiff -I$SIMSDKROOT/usr/include"
		export LDFLAGS="$LDFLAGS -L$LIB_DIR/jpeg_${BUILDINGFOR}_dylib/ -L$LIB_DIR/png_${BUILDINGFOR}_dylib/ -L$LIB_DIR/tiff_${BUILDINGFOR}_dylib/ -L$LIB_DIR"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=$IM_LIB_DIR --host=${BUILDINGFOR}-apple-darwin --disable-opencl \
			--disable-largefile --with-quantum-depth=8 --without-magick-plus-plus --without-perl --without-x \
			--disable-shared --disable-openmp --without-bzlib --without-freetype --without-threads --disable-dependency-tracking
		im_compile
		restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
	# join libMagickCore
	joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_core)
	if [ $joinlibs == "OK" ]; then
		echo "[|- COMBINE $ARCHS]"
		accumul=""
		for i in $ARCHS; do
			accumul="$accumul -arch $i $LIB_DIR/$LIBNAME_core.$i"
		done
		# combine the static libraries
		try lipo $accumul -create -output $LIB_DIR/libMagickCore.a
		echo "[+ DONE]"
	fi
	# join libMacigkWand
	joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_wand)
	if [ $joinlibs == "OK" ]; then
		echo "[|- COMBINE $ARCHS]"
		accumul=""
		for i in $ARCHS; do
			accumul="$accumul -arch $i $LIB_DIR/$LIBNAME_wand.$i"
		done
		# combine the static libraries
		try lipo $accumul -create -output $LIB_DIR/libMagickWand.a
		echo "[+ DONE]"
	fi
}
