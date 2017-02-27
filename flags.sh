#!/bin/bash

armflags () {
	export ARM_CC=$(xcrun -find -sdk iphoneos clang)
	export ARM_CXX=$(xcrun -find -sdk iphoneos clang++)
	export ARM_LD=$(xcrun -find -sdk iphoneos ld)

	
	export ARM_CFLAGS="-arch $1"
	export ARM_CFLAGS="$ARM_CFLAGS -I$IOSSDKROOT/usr/include"
	export ARM_CFLAGS="$ARM_CFLAGS -isysroot $IOSSDKROOT"
	export ARM_CFLAGS="$ARM_CFLAGS -miphoneos-version-min=$SDKMINVER"
	export ARM_CXXFLAGS="-arch $1"
	export ARM_CXXFLAGS="$ARM_CFLAGS -I$IOSSDKROOT/usr/include"
	export ARM_CXXFLAGS="$ARM_CFLAGS -isysroot $IOSSDKROOT"
	export ARM_CXXFLAGS="$ARM_CFLAGS -miphoneos-version-min=$SDKMINVER"
	export ARM_LDFLAGS="-arch $1 -isysroot $IOSSDKROOT"
	export ARM_LDFLAGS="$ARM_LDFLAGS -miphoneos-version-min=$SDKMINVER"
	
	export ARM_CFLAGS="$ARM_CFLAGS -O3 -fembed-bitcode"
	# uncomment this line if you want debugging stuff
	# export ARM_CFLAGS="$ARM_CFLAGS -O0 -g"

	# apply ARM_XX values
	export CC="$ARM_CC"
	export CXX="$ARM_CXX"
	export CFLAGS="$ARM_CFLAGS"
	export CXXFLAGS="$ARM_CXXFLAGS"
	export LD="$ARM_LD"
	export LDFLAGS="$ARM_LDFLAGS"

	# export what we are building for
	export BUILDINGFOR="$1"
}

intelflags () {
	export INTEL_CC=$(xcrun -find -sdk iphonesimulator clang)
	export INTEL_LD=$(xcrun -find -sdk iphonesimulator ld)
	
	export INTEL_CFLAGS="-arch $1"
	export INTEL_CFLAGS="$INTEL_CFLAGS -I$SIMSDKROOT/usr/include"
	
	# apply INTEL_CC values
	export CC="$INTEL_CC"
	export CCP="$INTEL_CC -E"
	export CFLAGS="$INTEL_CFLAGS"
	export LD="$INTEL_LD"
	
	# export what we are building for
	export BUILDINGFOR="$1"
}

save() {
	export OLD_CC="$CC"
	export OLD_CXX="$CXX"
	export OLD_CFLAGS="$CFLAGS"
	export OLD_CXXFLAGS="$CXXFLAGS"
	export OLD_LDFLAGS="$LDFLAGS"
	export OLD_CPP="$CPP"
}

restore () {
	export CC="$OLD_CC"
	export CXX="$OLD_CXX"
	export CFLAGS="$OLD_CFLAGS"
	export CXXFLAGS="$OLD_CXXFLAGS"
	export LDFLAGS="$OLD_LDFLAGS"
	export CPP="$OLD_CPP"
}
