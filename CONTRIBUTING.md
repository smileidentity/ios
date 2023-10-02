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
