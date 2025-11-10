# Release Notes

## 11.1.3 - November 10, 2025

### Changed
* Make Lottie a vendored framework for Cocoapods

### Removed
* Removed SmileIDSecurity dependency

## 11.1.2 - October 31, 2025

### Changed
* Improved liveness check user experience for faster, smoother head turn detection.
* Added the new EnhancedSmartSelfie™ animations in the instruction and capture screens.


## 11.1.1 - August 25, 2025

### Added
* Orientation helper to `SelfieViewModel` for consistent selfie image capture.

### Fixed
* Fixed document auto-capture not working when `autoCapture` is set to `.autoCaptureOnly`.

## 11.1.0 - July 31, 2025

### Added

* Introduce Sentry to track and report SmileID related errors on the iOS sdk. It is enabled by default using `enableCrashReporting: Bool = true,` on `SmileID.initialize()`
* Added `autoCaptureTimeout` that allows partners to override the default 10 seconds auto capture
  timeout
* Add new wrapper name `reactNativeExpo` for React Native Expo SDK.

### Changed

* Changed `enableAutoCapture` to `AutoCapture` enum to allow to allow partners change document capture options

### Removed

* Removed `AntiFraud` response in `JobStatus` calls
* Removed the default `ConsentInformation` set when no consent is passed
* Removed the default `ConsentInformation`

## 11.0.2 - July 10, 2025

### Changed
* Changed returned file paths for document and selfie captures from relative to absolute, allowing partners to access complete file locations.

## 11.0.1 - July 2, 2025

### Added

* Added option to disable document auto capture in DocV and Enhanced DocV

## 11.0.0

### Added 
 * Added a security feature to protect the payload between sdk and backend from unauthorized tampering.
 * Enhanced fraud signals collection to improve fraud prevention
  
### Changed
* Changes the `retry` flag to be a boolean instead of a string for prepUpload requests. This is a breaking change for stored offline jobs, where the job is written using an older sdk version and then submission is attempted using this version
* Made calculateSignature func public 

### Fixed
* Fixed a typographical error on the SmartSelfie instructions screen

## 10.5.3

### Changed
* Restructured consent object that is being sent to the backend API for biometric kyc, enhanced kyc and enhanced document verification

## 10.5.2

### Changed
* Require selfie recapture when retrying failed submission for Enhanced Smart Selfie Capture.

### Fixed
* Delegate callback order after submission for Biometric KYC and Document Verification jobs.

## 10.5.1

### Fixed
* Selfie submission error returned in success delegate callback.

## 10.5.0

* Update lottie-ios to minimum `v4.5.0`
* Changes the `allow_new_enroll` flag to be a boolean instead of a string for prepUpload requests and multi-part requests. This is a breaking change for stored offline jobs, where the job is written using an older sdk version and then submission is attempted using this version

## 10.4.2

* Added SmartSelfie™ capture only option for Enhanced SmartSelfie™ and SmartSelfie™ capture flows without submission accessible with `skipApiSubmission=true` on enroll and authentication products

## 10.4.1

* Make ConsentInformation optional in EnhancedDocV, EnhancedKYC and BiometricKYC

## 10.4.0

### Added
* Pass ConsentInformation in EnhancedDocV, EnhancedKYC and BiometricKYC

### Changed
* Timestamp consistency from date epoch to iso format 

## 10.3.5

### Added
* Default headers to all GET and POST requests: PartnerID, Source SDK and Source SDK Version.

### Fixed
* Document back image required when `captureBothSides` is false.

## 10.3.4

### Fixed
* Document capture screen title to reflect capture side

## 10.3.3

### Changed
* Device orientation instruction text to match Android

### Removed
* Pre-compiled `SelfieQualityModel.mlmodelc` file used for selfie quality check was producing files not supported by SPM.

## 10.3.2

### Fixed
* Allow navigation events to be handled inside `SmartSelfieResultDelegate` methods as opposed to providing concrete platform specific navigation implementation. 

### Changed
* Expose the initializers for `SelfieCaptureScreen` and `EnhancedSelfieCaptureScreen`

## 10.3.1

* Update version for podspec release tag.


## 10.3.0

* Fixed missing idType on Document Verification Jobs
* Introduce screens for the new Enhanced Selfie Capture Enrollment and Authentication Products.

## 10.2.17

* Added skipApiSubmission: Whether to skip api submission to SmileID and return only captured images on SmartSelfie enrollment, SmartSelfie authentic , Document verification and Enhanced DocV

## 10.2.16

### Fixed
* Clear images on retry or start capture with the same jobId

## 10.2.15

### Changed
* Split up `submitJob()` functionalities for BiometricKYC for easier readability and debugging.
* Remove setting job processing screen sucess state subtitle with `errorMessageRes`.
* Modify how we check for network failure due to internet connection and move the `isNetworkFailure()` function into a more appropriate scope.

### Fixed
* Improve how we handle offline job failure scenario.

## 10.2.14

### Changed
* Changed thresholds for liveness photos movement

## 10.2.13

### Added
* Modified access selfie and liveness images util functions

## 10.2.12

### Added
* Modified access for selfie instruction screen for use in wrappers

## 10.2.11

### Added
* Add metadata support
* Modified access for util methods for use in wrappers

## 10.2.10

### Added
* Document capture cleanup and optionally showing confirmation and returning the captured image if false
* Added new `requestTimeout` parameter to `SmileID` class initializers to allow configuration of network request timeouts.

### Changed
* Convert network service upload function to normal async/await from AsyncThrowingStream.
* Handle requestError with URLError and return localizedDescription for user facing alert message.
* Handle httpError and provide a user facing message for the alert.

## 10.2.9

### Added
* Document capture cleanup and optionally showing confirmation and returning the captured image if false

## 10.2.9

### Added
* Document capture cleanup and optionally showing confirmation and returning the captured image if false

## 10.2.8

### Changed
* Smartselfie captures now return relative file urls as the rest of the products

### Added
* Zip files from prepupload request

## 10.2.7

### Changed
* Replaced the Zip library to introduce in memory ziping during file upload
* Remove `prodUrl` and `testURl` from Config model struct since the `prod_url` and `test_url` keys are no longer used in the `smile_config.json` file.
* Disabled dark mode as we fix theming across the sdk
* Fixed ambigious file paths on responses

## 10.2.6

### Changed
* Removed `SmileID.setEnvironment()` since the API Keys are no longer shared between environments
* All polling methods now return a `AsyncThrowingStream<JobStatusResponse<T>, Error>` and instead of a timeout, if there is no error it'll return the last valid response and complete the stream.
* Fixed a bug where prep upload would not work for previously attempted API requests


## 10.2.5

#### Fixed
* Job status history full data parsing causing a crash during polling

## 10.2.4

#### Fixed
* Partner params fix on v2 endpoints

## 10.2.3

#### Added
* Add new cases to `ActionResult` including an unknown case to handle values that do not match the defined enum cases.
* Add a custom decoding initializer to ActionResult that supports defaulting unexpected values to the unknown case.

#### Fixed

* Fixed a bug where `SmileID.submitJob` would not work for previously attempted API requests

## 10.2.2

#### Fixed
*  Remove force unwrapping for getting files from storage

## 10.2.1

#### Added
*  Handle unauthorized camera status

## 10.2.0

#### Changed

* **Breaking Change:** Updated the networking layer to use Swift's `async/await` instead of Combine's `AnyPublisher` and now return `async` functions. This improves readability and aligns with modern Swift concurrency practices.
    * All instances where these methods are used have been updated accordingly.

## 10.1.6

#### Added

* Update generic errors with actual platform errors

#### Changed

* Made the `Color` extension initializer with hex values public.

## 10.1.5

#### Fixed

* Made the MultipartBody init func public
* Fixed decoding error for confidence value

## 10.1.4

#### Added

* Improved SmartSelfie Enrollment and Authentication times by moving to a synchronous API endpoint

#### Fixed

* Fixed a bug where invalid file paths were returned and retries did not work

## 10.1.3

#### Fixed

* Fix Lottie SPM dependency issues

## 10.1.2

#### Fixed

* Ignore `user_id`, `job_id`, and `job_type` fields in `extraPartnerParams`

## 10.1.1

#### Added

* Added an Offline Mode, enabled by calling `SmileID.setAllowOfflineMode(true)`. If a job is attempted while the device is offline, and offline mode has been enabled, the UI will complete successfully and the job can be submitted at a later time by calling `SmileID.submitJob(jobId)`

## 10.1.0
* Add PrivacyInfo Manifest
* Added polling extensions for products

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
