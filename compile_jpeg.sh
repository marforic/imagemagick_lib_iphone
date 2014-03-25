#!/bin/bash

jpeg_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
	try cp $JPEG_LIB_DIR/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.$BUILDINGFOR
	try cp $JPEG_LIB_DIR/lib/libjpeg.dylib $LIB_DIR/jpeg_${BUILDINGFOR}_dylib/libjpeg.dylib
	if [[ "$BUILDINGFOR" == "x86_64" ]]; then  # last, copy the include files
		try cp $JPEG_LIB_DIR/include/*.h $LIB_DIR/include/jpeg/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

jpeg () {
	echo "[+ JPEG: $1]"
	cd $JPEG_DIR
	
	LIBPATH_jpeg=libjpeg.a
	LIBNAME_jpeg=`basename $LIBPATH_jpeg`
	
	if [ "$1" == "armv7" ] || [ "$1" == "armv7s" ]; then
		save
		armflags $1
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static --host=arm-apple-darwin
		jpeg_compile
		restore
	elif [ "$1" == "x86_64" ]; then
		save
		intelflags
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=$JPEG_LIB_DIR --enable-shared --enable-static --host=x86_64-apple-darwin
		jpeg_compile
		restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
	joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_jpeg)
	if [ $joinlibs == "OK" ]; then
		echo "[|- COMBINE $ARCHS]"
		accumul=""
		for i in $ARCHS; do
			accumul="$accumul -arch $i $LIB_DIR/$LIBNAME_jpeg.$i"
		done
		# combine the static libraries
		try lipo $accumul -create -output $LIB_DIR/$LIBNAME_jpeg
		echo "[+ DONE]"
	fi
}
