
# Release Notes
## 10.0.12 (Unreleased)

## 10.0.11

#### Fixed
* PartnerParams extras fixed to be in the correct format for the requests
* PartnerParams extras fixed to cater for the Photo param used in sandbox testing


## 10.0.10
* Set `IdInfo.entered` to true for Biometric KYC Jobs

## 10.0.9
* Carthage support

## 10.0.8
* Exposed individual components as Swift UI Components
* Removed the Skip Button from Back of ID Capture
* Added `instructionsHeroImage` as a new parameter to `DocumentCaptureScreen`
* Added `heroImage` as a new parameter to `DocumentCaptureInstructionsScreen`
* Updated Document Verification hero images

## 10.0.7

#### Fixed

* Improvements to the selfie capture experience

## 10.0.6

#### Fixed

* Allow agent mode in Biometric KYC

## 10.0.5

#### Fixed

* Fixed captureBothSides on iOS being inverted

## 10.0.4

#### Fixed

* Fixed missing selfie instructions screen on DocV and EnhancedDocV
* Fixed broken disable capture both sides flag
* Fixed show skip button on capture both sides

## 10.0.3

#### Added

* Added allowNewEnroll on SmartSelfie, BiometricKYC, DocV and EnhancedDocV

#### Fixed

* Fixed missing callbackUrl

## 10.0.2

### Fixed

* Fixed a bug on iOS 14 devices where the document and selfie cutouts were white insteaad of transparent

## 10.0.1

### Fixed

* Fixed missing info.json issue on Smartselfie Enrollment and Smartselfie Authentication

## 10.0.0

* No changes

## 10.0.0-beta14

### Changed

* Removed DocumentVerificationResultDelegate from extending AnyObject so it doesn't have to always be used in classes
* Removed EnhancedDocumentVerificationResultDelegate from extending AnyObject so it doesn't have to always be used in classes

## 10.0.0-beta13

### Added

* Enhanced KYC (synchronous)

### Changed

* Updated document capture to preserve aspect ratio in preview
* Updated visibility of networking models to public

## 10.0.0-beta12

### Added

* Consent Screen SwiftUI View

### Removed

* Biometric KYC no longer bundles the Consent Screen
* Biometric KYC no longer bundles an ID Type selector or input

## 10.0.0-beta11

### Added

* Biometric KYC
* Consent Screen
* BVN OTP API calls and models
* Added `extras` as optional params on all job types
* Added `allowAgentMode` option on Document Verification and Enhanced Document Verification

### Changed

* Default to `production` on `SmileID.initialize()`
* Increased selfie capture resolution to 640px

### Fixed

* Fixed missing `IdInfo` initializer

### 10.0.0-beta10

#### Added

* Enhanced Document Verification
* New JobStatusResponses that depend on the job type
* Set the callback URL by calling `SmileID.setCallbackURL(_:)`

#### Changed

* Renamed `DocumentCaptureResultDelegate` -> `DocumentVerificationResultDelegate`
* Delegate types updated to accept generic `JobStatusResponse` objects
* Provide `nil` as default values for `userId` and `jobId` on `AuthenticationRequest`
* Made public the properties in `ServicesResponse` and its nested classes

#### Fixed

* Document Verification UI bugs
* Fixed a bug where Services models would have incorrect or duplicate data

### 10.0.0-beta09

#### Fixed

* Fixed a bug where Document Verification results were not being delivered to the delegate

### 10.0.0-beta08

#### Added

* Document Verification
* Navigation router using `UINavigationController`
* Linting within Xcode
* Convenience method for partners to poll the `jobStatus` endpoint

#### Changed

* Return images captured from selfie capture and document capture as URLs

#### Removed

* `filename` property from `PrepUploadRequest`
* `jobStatus` polling from `SmartSelfieAuthentication`, `SmartSelfieEnrollment` and `DocumentVerification`

### Dependencies

* SwiftLint

### 10.0.0-beta07

#### Changed

* Declare `jobType` property of `PartnerParams` as optional

### 10.0.0-beta06

#### Changed

* Declare `jobType` property of `AuthenticationRequest` as optional

### 10.0.0-beta05

#### Changed

* Expose `sourceSdk` and `sourceSdkVersion` initializers and properties

### 10.0.0-beta04

#### Changed

* Expose `AuthenticationRequest` and `AuthenticationResponse` initializers and properties

### 10.0.0-beta03

#### Changed

* Set default value for config param on `initialize` method
* Expose initializers for `PartnerParams` and `EnhancedKycAsycResponse` models

### 10.0.0-beta02

#### Added

* Enhanced KYC Async API endpoint

#### Changed

* Point Podspec to public repo
* Point Pacakge.swift to the Resource directory
* Rename ImageType enums to drop PNG support
* Add a `SmileID.version` constant

#### Fixed

* Fix bug where reenroll is enabled on every job

### 10.0.0-beta01

#### Added

* Initial release 🎉
* SmartSelfie™ Authentication and Enrollment
* Theming
* Networking

#### Dependencies

* Zip

