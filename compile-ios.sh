#!/bin/sh

# Defaults
set -e
oniguruma='6.9.3'

unset CFLAGS
unset CXXFLAGS
unset LDFLAGS

#  Onig.
if [ ! -f onig-$oniguruma.tar.gz ]; then
  curl -LO https://github.com/kkos/oniguruma/releases/download/v$oniguruma/onig-$oniguruma.tar.gz
  tar zxf onig-$oniguruma.tar.gz
  echo "Downloaded onig-$oniguruma. Patch it for ios_system compatibility"
  exit 1
fi

# Start building.
echo "Building..."
MAKEJOBS="$(sysctl -n hw.ncpu || echo 1)"
CC_="$(xcrun -f clang || echo clang)"

builddir="${TMPDIR:-/tmp}/${RANDOM:-'xxxxx'}-compile-ios-build"
cwd="$(realpath "$PWD" 2>/dev/null || echo "$PWD")"

t_exit() {
cat << EOF

A error as occured.
    oniguruma location: $builddir/onig/onig-$oniguruma
    jq location: $cwd

    Provide config.log and console logs when posting a issue.

EOF
}
trap t_exit ERR

mkdir -p "$builddir"
cp -a onig-$oniguruma "$builddir"
cd "$builddir/"
 for arch in arm64 x86_64; do
     if [ $arch = x86_64 ]; then
         SYSROOT="$(xcrun -f --sdk iphonesimulator --show-sdk-path)"
         ios_system_arch=ios-arm64_x86_64-simulator
         ios_system_host=x86_64-apple-darwin
         ios_system_build=x86_64-apple-darwin
     else
         SYSROOT="$(xcrun -f --sdk iphoneos --show-sdk-path)"
         ios_system_arch=ios-arm64
         ios_system_host=armv8-apple-darwin
         ios_system_build=x86_64-apple-darwin
     fi

     #HOST="${arch}-apple-darwin"
     #[[ "${arch}" = "arm64" ]] && HOST="aarch64-apple-darwin"

     CFLAGS="-arch $arch -miphoneos-version-min=14.0 -isysroot $SYSROOT $CFLAGS_ -D_REENTRANT -F $cwd/ios_system.xcframework/$ios_system_arch -framework ios_system"
     LDFLAGS="-arch $arch -miphoneos-version-min=14.0 -isysroot $SYSROOT $LDFLAGS_ -F $cwd/ios_system.xcframework/$ios_system_arch -framework ios_system -dynamiclib"
     CC="$CC_ $CFLAGS"

     cd "$builddir/onig-$oniguruma"
     CC="$CC" LDFLAGS="$LDFLAGS" ./configure \
         --host=$ios_system_host \
         --build=$ios_system_build \
         --enable-shared=no \
         --enable-static=yes \
         --prefix=/ \
         cross_compiling=yes

     make -j$MAKEJOBS install DESTDIR="$cwd/ios/onig/$arch"
     make clean
     
     # Jump back to JQ.
     cd "$cwd"
     make clean
     [ ! -f ./configure ] && autoreconf -ivf

     CC="$CC_ $CFLAGS" LDFLAGS="$LDFLAGS" ./configure \
         --host=$ios_system_host \
         --build=$ios_system_build \
         --prefix=/ \
         --enable-docs=no \
         --with-oniguruma="$cwd/ios/onig/$arch" \
         --disable-maintainer-mode \
         cross_compiling=yes

     make -j$MAKEJOBS install DESTDIR="$cwd/ios/jq/$arch"
     make clean
 done

mkdir -p "$cwd/ios/dest/lib"
# lipo, make a static lib.
#lipo -create -output ${cwd}/ios/dest/lib/libonig.a ${cwd}/ios/onig/{i386,x86_64,armv7,armv7s,arm64}/lib/libonig.a
#lipo -create -output ${cwd}/ios/dest/lib/libjq.a ${cwd}/ios/jq/{i386,x86_64,armv7,armv7s,arm64}/lib/libjq.a
#lipo -create -output ${cwd}/ios/dest/lib/libonig.a ${cwd}/ios/onig/{x86_64,arm64}/lib/libonig.a
#lipo -create -output ${cwd}/ios/dest/lib/libjq.a ${cwd}/ios/jq/{x86_64,arm64}/lib/libjq.a

# Take the arm64 headers- the most common target.
cp -r "$cwd/ios/jq/arm64/include" "$cwd/ios/dest/"
#rm -rf ${cwd}/build/ios/{i386,x86_64,armv7,armv7s,arm64}
rm -rf "$cwd/build/ios/x86_64,arm64"

framework_dir=ios/Release-iphoneos/jq.framework
rm -rf "$framework_dir"
mkdir -p "$framework_dir"
mkdir -p "$framework_dir/Headers"
cp ios/jq/arm64/bin/jq "$framework_dir/jq"
cp basic_Info.plist "$framework_dir/Info.plist"
plutil -replace CFBundleExecutable -string jq "$framework_dir/Info.plist"
plutil -replace CFBundleName -string jq "$framework_dir/Info.plist"
plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.jq  "$framework_dir/Info.plist"
install_name_tool -id @rpath/jq.framework/jq "$framework_dir/jq"

framework_dir=ios/Release-iphonesimulator/jq.framework
rm -rf "$framework_dir"
mkdir -p "$framework_dir"
mkdir -p "$framework_dir/Headers"
cp ios/jq/x86_64/bin/jq "$framework_dir/jq"
cp basic_Info_Simulator.plist "$framework_dir/Info.plist"
plutil -replace CFBundleExecutable -string jq "$framework_dir/Info.plist"
plutil -replace CFBundleName -string jq "$framework_dir/Info.plist"
plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.jq  "$framework_dir/Info.plist"
install_name_tool -id @rpath/jq.framework/jq "$framework_dir/jq"

rm -rf jq.xcframework
xcodebuild -create-xcframework -framework ios/Release-iphoneos/jq.framework -framework ios/Release-iphonesimulator/jq.framework -output ios/jq.xcframework

echo "Output to $cwd/ios"

