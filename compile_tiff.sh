#!/bin/bash

tiff_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
	cp $TIFF_LIB_DIR/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.$BUILDINGFOR
	cp $TIFF_LIB_DIR/lib/libtiff.5.dylib $LIB_DIR/tiff_${BUILDINGFOR}_dylib/libtiff.dylib
	if [[ "$BUILDINGFOR" == "x86_64" ]]; then  # last, copy the include files
		cp $TIFF_LIB_DIR/include/*.h $LIB_DIR/include/tiff/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

tiff () {
	echo "[+ TIFF: $1]"
	cd $TIFF_DIR
	
	LIBPATH_tiff=libtiff.a
	LIBNAME_tiff=`basename $LIBPATH_tiff`
	
	if [ "$1" == "armv7" ] || [ "$1" == "armv7s" ]; then
		save
		armflags $1
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=$TIFF_LIB_DIR --enable-shared --enable-static --disable-cxx --host=arm-apple-darwin
		tiff_compile
		restore
	elif [ "$1" == "x86_64" ]; then
		save
		intelflags
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=$TIFF_LIB_DIR --enable-shared --enable-static --disable-cxx --host=x86_64-apple-darwin
		tiff_compile
		restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
	
	joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_tiff)
	if [ $joinlibs == "OK" ]; then
		echo "[|- COMBINE $ARCHS]"
		accumul=""
		for i in $ARCHS; do
			accumul="$accumul -arch $i $LIB_DIR/$LIBNAME_tiff.$i"
		done
		# combine the static libraries
		try lipo $accumul -create -output $LIB_DIR/$LIBNAME_tiff
		echo "[+ DONE]"
	fi
}
