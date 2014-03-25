#!/bin/bash

png_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
	try cp $PNG_LIB_DIR/lib/$LIBPATH_png $LIB_DIR/libpng.a.$BUILDINGFOR
	try cp $PNG_LIB_DIR/lib/$LIBPATH_png_dylib $LIB_DIR/png_${BUILDINGFOR}_dylib/libpng.dylib
	if [[ "$BUILDINGFOR" == "x86_64" ]]; then  # last, copy the include files
		try cp $PNG_LIB_DIR/include/libpng*/* $LIB_DIR/include/png/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

png () {
	echo "[+ PNG: $1]"
	cd $PNG_DIR
	
	LIBPATH_png=libpng16.a
	LIBPATH_png_dylib=libpng16.dylib
	
	if [ "$1" == "armv7" ] || [ "$1" == "armv7s" ]; then
		save
		armflags $1
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		try ./configure prefix=$PNG_LIB_DIR --enable-shared --enable-static --host=arm-apple-darwin
		png_compile
		restore
	elif [ "$1" == "x86_64" ]; then
		save
		intelflags
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		try ./configure prefix=$PNG_LIB_DIR --enable-shared --enable-static --host=x86_64-apple-darwin
		png_compile
		restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
	joinlibs=$(check_for_archs $LIB_DIR/libpng.a)
	if [ $joinlibs == "OK" ]; then
		echo "[|- COMBINE $ARCHS]"
		accumul=""
		for i in $ARCHS; do
			accumul="$accumul -arch $i $LIB_DIR/libpng.a.$i"
		done
		# combine the static libraries
		try lipo $accumul -create -output $LIB_DIR/libpng.a
		echo "[+ DONE]"
	fi
}
