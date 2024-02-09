# Smile Identity iOS SDK

## Overview

This repo contains all the code required to run the Smile Identity SDK. The project folder structure is described below.

- `Example` - A sample app that demonstrates the SDKs features
- `Sources`- Contains all UI, CV and networking source code
- `Tests`- Unit tests for the SDK business logic 

## Requirements

- iOS 13 or higher
- Xcode 14 or higher

## CI Setup

The `GITHUB_PAT_IOS_CERTIFICATES_REPO_B64` secret is created by running

```shell
echo -n smileidentity:your_personal_access_token | base64
```

`your_personal_access_token` is the fine-grained personal access token created that has permissions
to the [`smileidentity/ios-certificates`](https://github.com/smileidentity/ios-certificates) repo.

A new token can be obtained at https://github.com/settings/personal-access-tokens/new



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

### Contributing Code

When contributing code to the project, please ensure your contributions adhere to the formatting standards and quality checks enforced by our pre-commit hooks. Here's what you need to know:

- **Manual Checks**: In case linting checks fail, you'll need to review the changes, stage them, and commit again. This might include running `git add` for any automatically formatted files or making manual adjustments as suggested by the pre-commit checks.

### Further Reading and Resources

- **[pre-commit Official Documentation](https://pre-commit.com/)**: Learn more about pre-commit, including advanced configurations and how to create custom hooks.
- **[SwiftLint GitHub Repository](https://github.com/realm/SwiftLint)**: Explore Swiftlint to learn more about enforcing Swift styles and conventions.
- **[SwiftFormat GitHub Repository](https://github.com/nicklockwood/SwiftFormat)**: Explore SwiftFormat for comprehensive Swift code formatting rules and configurations.

