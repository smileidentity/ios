#!/bin/bash
set -e

WORKING_DIR=$(pwd)
FRAMEWORK_FOLDER_NAME="Frameworks"

create_xcframework() {
  FRAMEWORK_NAME=$1
  FRAMEWORK_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/${FRAMEWORK_NAME}.xcframework"
  BUILD_SCHEME="${FRAMEWORK_NAME}Framework"

  SIMULATOR_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/Simulator.xcarchive"
  IOS_DEVICE_ARCHIVE_PATH="${WORKING_DIR}/${FRAMEWORK_FOLDER_NAME}/iOS.xcarchive"

  rm -rf "${FRAMEWORK_PATH}"
  echo "Deleted old ${FRAMEWORK_PATH} …"

  echo "Archiving ${FRAMEWORK_NAME} …"

  xcodebuild archive ONLY_ACTIVE_ARCH=NO -scheme ${BUILD_SCHEME} -destination="generic/platform=iOS Simulator" -archivePath "${SIMULATOR_ARCHIVE_PATH}" -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

  xcodebuild archive -scheme ${BUILD_SCHEME} -destination="generic/platform=iOS" -archivePath "${IOS_DEVICE_ARCHIVE_PATH}" -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

  xcodebuild -create-xcframework -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -framework ${IOS_DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -output "${FRAMEWORK_PATH}"

  rm -rf "${SIMULATOR_ARCHIVE_PATH}"
  rm -rf "${IOS_DEVICE_ARCHIVE_PATH}"
}

create_xcframework "SmileID"

open "${WORKING_DIR}"