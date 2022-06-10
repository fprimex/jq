#!/bin/sh

FRAMEWORK_DIR=ios/Release-iphoneos/jq.framework
rm -rf ${FRAMEWORK_DIR}
mkdir -p ${FRAMEWORK_DIR}
mkdir -p ${FRAMEWORK_DIR}/Headers
cp ios/jq/arm64/bin/jq ${FRAMEWORK_DIR}/jq
cp basic_Info.plist ${FRAMEWORK_DIR}/Info.plist
plutil -replace CFBundleExecutable -string jq ${FRAMEWORK_DIR}/Info.plist
plutil -replace CFBundleName -string jq ${FRAMEWORK_DIR}/Info.plist
plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.jq  ${FRAMEWORK_DIR}/Info.plist
install_name_tool -id @rpath/jq.framework/jq   ${FRAMEWORK_DIR}/jq

FRAMEWORK_DIR=ios/Release-iphonesimulator/jq.framework
rm -rf ${FRAMEWORK_DIR}
mkdir -p ${FRAMEWORK_DIR}
mkdir -p ${FRAMEWORK_DIR}/Headers
cp ios/jq/x86_64/bin/jq ${FRAMEWORK_DIR}/jq
cp basic_Info_Simulator.plist ${FRAMEWORK_DIR}/Info.plist
plutil -replace CFBundleExecutable -string jq ${FRAMEWORK_DIR}/Info.plist
plutil -replace CFBundleName -string jq ${FRAMEWORK_DIR}/Info.plist
plutil -replace CFBundleIdentifier -string Nicolas-Holzschuch.jq  ${FRAMEWORK_DIR}/Info.plist
install_name_tool -id @rpath/jq.framework/jq ${FRAMEWORK_DIR}/jq

rm -rf jq.xcframework
xcodebuild -create-xcframework -framework ios/Release-iphoneos/jq.framework -framework ios/Release-iphonesimulator/jq.framework -output jq.xcframework
