## 10.0.0-beta13

### Added

### Changed
- Updated document capture to preserve aspect ratio in preview
- Updated visibility of networking models to public

## 10.0.0-beta12

### Added
- Consent Screen SwiftUI View

### Removed
- Biometric KYC no longer bundles the Consent Screen
- Biometric KYC no longer bundles an ID Type selector or input

## 10.0.0-beta11

### Added
- Biometric KYC
- Consent Screen
- BVN OTP API calls and models
- Added `extras` as optional params on all job types
- Added `allowAgentMode` option on Document Verification and Enhanced Document Verification

### Changed
- Default to `production` on `SmileID.initialize()`
- Increased selfie capture resolution to 640px

### Fixed
- Fixed missing `IdInfo` initializer

### Removed

## 10.0.0-beta10

### Added
- Enhanced Document Verification
- New JobStatusResponses that depend on the job type
- Set the callback URL by calling `SmileID.setCallbackURL(_:)`

### Changed
- Renamed `DocumentCaptureResultDelegate` -> `DocumentVerificationResultDelegate`
- Delegate types updated to accept generic `JobStatusResponse` objects
- Provide `nil` as default values for `userId` and `jobId` on `AuthenticationRequest`
- Made public the properties in `ServicesResponse` and its nested classes

### Fixed
- Document Verification UI bugs
- Fixed a bug where Services models would have incorrect or duplicate data

## 10.0.0-beta09

### Fixed
- Fixed a bug where Document Verification results were not being delivered to the delegate

## 10.0.0-beta08

### Added
- Document Verification
- Navigation router using `UINavigationController`
- Convenience method for partners to poll the `jobStatus` endpoint

### Changed
- Return images captured from selfie capture and document capture as URLs

### Removed
- `filename` property from `PrepUploadRequest`
- `jobStatus` polling from `SmartSelfieAuthentication`, `SmartSelfieEnrollment` and `DocumentVerification`

### Dependencies
- SwiftLint

## 10.0.0-beta07

### Changed
- Declare `jobType` property of `PartnerParams` as optional

## 10.0.0-beta06

### Changed
- Declare `jobType` property of `AuthenticationRequest` as optional

## 10.0.0-beta05

### Changed
- Expose `sourceSdk` and `sourceSdkVersion` initializers and properties

## 10.0.0-beta04

### Changed
- Expose `AuthenticationRequest` and `AuthenticationResponse` initializers and properties

## 10.0.0-beta03

### Changed
- Set default value for config param on `initialize` method
- Expose initializers for `PartnerParams` and `EnhancedKycAsycResponse` models

## 10.0.0-beta02

### Added

- Enhanced KYC Async API endpoint

### Changed
- Point Podspec to public repo
- Point Pacakge.swift to the Resource directory
- Rename ImageType enums to drop PNG support
- Add a `SmileID.version` constant

### Fixed

- Fix bug where reenroll is enabled on every job

## 10.0.0-beta01

### Added
- Initial release 🎉
- SmartSelfie™ Authentication and Enrollment
- Theming
- Networking

### Dependencies
- Zip
