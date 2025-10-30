# Smile Identity iOS SDK

## Overview

This repo contains all the code required to run the Smile Identity SDK. The project folder structure is described below.

- `Example` - A sample app that demonstrates the SDKs features
- `Sources`- Contains all UI, CV and networking source code
- `Tests`- Unit tests for the SDK business logic

We use [`mint`](https://github.com/yonaskolb/Mint) for running swift command line tool packages.
We use [`rake`](https://github.com/ruby/rake) for task automation.

## Dependency Resolution

### Ruby Dependencies
Install Ruby dependencies using Bundler:
```shell
bundle install
```

### Swift Package Dependencies
The project uses Swift Package Manager for dependencies. Xcode will automatically resolve packages when you open the project, but you can also resolve them manually:
```shell
xcodebuild -resolvePackageDependencies
```

### Mint Dependencies
Install Mint-managed tools:
```shell
mint bootstrap
```

## Requirements

- iOS 13 or higher
- Xcode 14 or higher

## Code Formatting

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for automatic code formatting. The configuration is defined in `.swiftformat` at the root of the project.

### Local Setup

Install SwiftFormat using Homebrew:
```shell
brew install swiftformat
```

## Code Linting

This project uses [SwiftLint](https://github.com/realm/SwiftLint) for enforcing Swift style and conventions. SwiftLint is required for the build script phase to run properly.

### Local Setup

Install SwiftLint using Homebrew:
```shell
brew install swiftlint
```

### Usage

Format all Swift files in the project:
```shell
swiftformat .
```

Check for formatting issues without making changes:
```shell
swiftformat --lint .
```

### CI Integration

SwiftFormat linting is automatically run on all pull requests. The CI will fail if code is not properly formatted according to the project's configuration.

## Example App Tests

```shell
bundle exec rake test:example
```

## CI Setup

The project uses Xcode Cloud for building the Example project. This eliminates the need for manual certificate and provisioning profile management that was previously handled through fastlane.

## Optional: Code Formatting and Quality Checks

To ensure our project maintains high-quality standards and consistency across contributions, we leverage the `pre-commit` framework for automated code formatting and quality checks. This tool helps us enforce coding standards, perform syntax checks, and automatically format code according to predefined rules before commits are made, reducing the need for manual code review for stylistic concerns.

### Setting Up `pre-commit` in Your Development Environment

1. **Install `pre-commit`**: To get started, you need to have `pre-commit` installed on your local machine. You can install it using Homebrew (for macOS users), pip (for Python users), or another method detailed in the official [pre-commit installation guide](https://pre-commit.com/#installation).

    ```bash
    # Using Homebrew
    brew install pre-commit

    # Using pip
    pip install pre-commit

2. **Install the Pre-commit Hooks**: Navigate to the root of the cloned repository and install the pre-commit hooks defined in our `.pre-commit-config.yaml` file:

    ```bash
    pre-commit install
    ```

This setup process ensures that the pre-commit hooks are triggered automatically before each commit, applying code formatting and running any configured checks.

## Other Notes

When contributing code to the project, please ensure your contributions adhere to the formatting standards and quality checks enforced by our pre-commit hooks. Here's what you need to know:

- **pre-commit hook** It is recommended to set up a pre-commit hook (SwiftFormat - formatting, SwiftLint - swift lints). To
  do so, add the following to `.git/hooks/pre-commit` this will lint, format as well as detect additions or deletion of SDK only swift files which 
  is essential to keep the project files in sync since we use the sample app/cocoapods for primary development and this may affect carthage releases
  if files are not in sync
  ```
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
  ```
- **Manual Checks**: In case linting checks fail, you'll need to review the changes, stage them, and commit again. This might include running `git add` for any automatically formatted files or making manual adjustments as suggested by the pre-commit checks.

### Further Reading and Resources

- **[SwiftLint GitHub Repository](https://github.com/realm/SwiftLint)**: Explore Swiftlint to learn more about enforcing Swift styles and conventions.
- **[SwiftFormat GitHub Repository](https://github.com/nicklockwood/SwiftFormat)**: Explore SwiftFormat for comprehensive Swift code formatting rules and configurations.
