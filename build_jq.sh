#! /bin/sh

OSX_SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
SIM_SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)

if [ ! -f modules/oniguruma/README ]; then
  git submodule update --init
fi

mkdir -p ${PWD}/ios_system.xcframework/ios-arm64

if [ ! -f configure ]; then
  autoreconf -fi
fi

#make distclean

export CC=clang
export CXX=clang++
export CC_FOR_BUILD="clang -isysroot ${OSX_SDKROOT}"
export CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot ${IOS_SDKROOT} -fembed-bitcode -Dstat64=stat -Dlstat64=lstat -Dfstat64=fstat -DUSE_GLIBC_STDIO=1 -I${PWD}"
export CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot ${IOS_SDKROOT} -fembed-bitcode -Dstat64=stat -Dlstat64=lstat -Dfstat64=fstat -DUSE_GLIBC_STDIO=1 -I${PWD}"
export CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot ${IOS_SDKROOT} -fembed-bitcode -Dstat64=stat -Dlstat64=lstat -Dfstat64=fstat -DUSE_GLIBC_STDIO=1 -I${PWD}"
#export LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot ${IOS_SDKROOT} -fembed-bitcode -dynamiclib -F ${PWD}/ios_system.xcframework/ios-arm64 -framework ios_system"
export LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot ${IOS_SDKROOT} -fembed-bitcode -dynamiclib -F ${PWD}/ios_system.xcframework/ios-arm64 -framework ios_system"

#./configure --build=x86_64-apple-darwin --host=arm64-apple-darwin cross_compiling=yes \
#  --with-oniguruma=builtin --disable-maintainer-mode

make -j4 --quiet
#make check

echo "finished first build"
exit 0

mkdir -p ios_system.xcframework/ios-arm64

for binary in jq
do 
  FRAMEWORK_DIR=build/Release-iphoneos/$binary.framework
  rm -rf ${FRAMEWORK_DIR}
  mkdir -p ${FRAMEWORK_DIR}
  mkdir -p ${FRAMEWORK_DIR}/Headers
  cp src/dash ${FRAMEWORK_DIR}/$binary
  cp basic_Info.plist ${FRAMEWORK_DIR}/Info.plist
  plutil -replace CFBundleExecutable -string $binary ${FRAMEWORK_DIR}/Info.plist
  plutil -replace CFBundleName -string $binary ${FRAMEWORK_DIR}/Info.plist
  plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$binary  ${FRAMEWORK_DIR}/Info.plist
  install_name_tool -id @rpath/$binary.framework/$binary   ${FRAMEWORK_DIR}/$binary
done

mkdir -p ${PWD}/ios_system.xcframework/ios-arm64_x86_64-simulator

make distclean
./configure CC=clang CXX=clang++ \
	CC_FOR_BUILD="clang -isysroot ${OSX_SDKROOT}" \
	CFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot ${SIM_SDKROOT} -fembed-bitcode -Dstat64=stat -Dlstat64=lstat -Dfstat64=fstat -DUSE_GLIBC_STDIO=1 -I${PWD}" \
	CPPFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot ${SIM_SDKROOT} -fembed-bitcode -Dstat64=stat -Dlstat64=lstat -Dfstat64=fstat -DUSE_GLIBC_STDIO=1 -I${PWD}" \
	CXXFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot ${SIM_SDKROOT} -fembed-bitcode -Dstat64=stat -Dlstat64=lstat -Dfstat64=fstat -DUSE_GLIBC_STDIO=1 -I${PWD}" \
	LDFLAGS="-arch x86_64 -miphonesimulator-version-min=14.0 -isysroot ${SIM_SDKROOT} -fembed-bitcode -dynamiclib -F ${PWD}/ios_system.xcframework/ios-arm64_x86_64-simulator -framework ios_system" \
	--build=x86_64-apple-darwin --host=x86_64-apple-darwin cross_compiling=yes \
  --with-oniguruma=builtin --disable-maintainer-mode
make -j4 --quiet
#make check

for binary in jq
do 
  FRAMEWORK_DIR=build/Release-iphonesimulator/$binary.framework
  rm -rf ${FRAMEWORK_DIR}
  mkdir -p ${FRAMEWORK_DIR}
  mkdir -p ${FRAMEWORK_DIR}/Headers
  cp src/dash ${FRAMEWORK_DIR}/$binary
  cp basic_Info_Simulator.plist ${FRAMEWORK_DIR}/Info.plist
  plutil -replace CFBundleExecutable -string $binary ${FRAMEWORK_DIR}/Info.plist
  plutil -replace CFBundleName -string $binary ${FRAMEWORK_DIR}/Info.plist
  plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.$binary  ${FRAMEWORK_DIR}/Info.plist
  install_name_tool -id @rpath/$binary.framework/$binary   ${FRAMEWORK_DIR}/$binary
done

# then, merge them into XCframeworks:
for framework in jq
do
   rm -rf $framework.xcframework
   xcodebuild -create-xcframework -framework build/Release-iphoneos/$framework.framework -framework build/Release-iphonesimulator/$framework.framework -output $framework.xcframework
done
