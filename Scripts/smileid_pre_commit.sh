#!/bin/sh

# Path to the XCode pro update script
RUBY_SCRIPT_PATH="./Scripts/update_compile_sources.rb"
swift_files_added_removed=false
xcodeproj_modified=false

# Check for added or deleted Swift files in "Sources" folder and its subfolders
if git diff --cached --name-status | grep -E '^[AD][[:space:]]Sources/.*\.swift$'; then
    swift_files_added_removed=true
fi

# Check if the .xcodeproj file is modified and staged
if git diff --cached --name-only | grep -e 'SmileID.xcodeproj/project.pbxproj$'; then
    xcodeproj_modified=true
fi

# Get a list of all staged Swift files
STAGED_SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.swift$')

echo "Automatically running SwiftFormat on all staged Swift files..."
echo $STAGED_SWIFT_FILES | xargs swiftformat

# Exit early if no Swift files are staged
if [ -z "$STAGED_SWIFT_FILES" ]; then
  exit 0
fi

# Run SwiftLint for each staged Swift file
echo "Running SwiftLint..."
SWIFTLINT_FAILED=0
for FILE in $STAGED_SWIFT_FILES; do
  swiftlint lint --quiet --path "$FILE"
  if [ $? -ne 0 ]; then
    SWIFTLINT_FAILED=1
  fi
done

# Exit with an error if SwiftLint failed
if [ $SWIFTLINT_FAILED -ne 0 ]; then
  echo "Swift files formatted with SwiftFormat and added to staging"
  # Optionally, you could remove the exit here to allow the script to continue
  exit 1
fi

# Output results
if [ "$swift_files_added_removed" = true ] && [ "$xcodeproj_modified" = true ]; then
    echo "Added Swift files and modified .xcodeproj found."
    exit 0
elif [ "$swift_files_added_removed" = true ]; then
    # Update the XCode project file
    echo "Added Swift files found, but .xcodeproj is not modified, Adding to xcode project file."
    ruby $RUBY_SCRIPT_PATH
    if [ $? -ne 0 ]; then
      echo "Ruby script failed. Commit aborted."
      exit 1
    fi
    echo "Project file updated."
    exit 1
fi

# Otherwise, exit successfully
exit 0
