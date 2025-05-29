# SmileID SDK Payload Signing Technical Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Dependencies](#dependencies)
4. [Implementation Details](#implementation-details)
5. [Security Considerations](#security-considerations)
6. [Integration Guide](#integration-guide)
7. [Testing & Verification](#testing--verification)
8. [Troubleshooting](#troubleshooting)

## Overview

The SmileID SDK implements a robust payload signing mechanism to ensure the integrity and authenticity of API requests. This system uses HMAC-SHA256 signatures with PBKDF2 key derivation to protect request payloads and headers from tampering during transmission.

### Key Features
- **HMAC-SHA256** message authentication
- **PBKDF2** key derivation with 200,000 iterations
- **Dynamic salt generation** using payload size and timestamp
- **Header filtering** for SmileID-specific headers
- **Base64 encoding** for binary data transmission

## Architecture

### Component Overview

```
┌─────────────────────────┐
│   ServiceRunnable       │
│  (Request Initiator)    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  SmileIDCryptoManager   │
│   (Signature Creator)   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│    HTTP Headers         │
│ SmileID-Request-Mac: .. │
└─────────────────────────┘
```

### Core Components

1. **SmileIDCryptoManager**: Central cryptography manager implementing the signing logic
2. **ServiceRunnable**: Protocol extension that integrates signing into API requests
3. **HTTPHeader**: Structure for managing request headers including the MAC header

## Dependencies

### External Dependencies
- **SmileIDSecurity** (v1.0.1+): External package containing the SECRET resource
  - Repository: `https://github.com/smileidentity/smile-id-security`
  - Provides the secret key material for HMAC generation

### System Dependencies
- **CryptoKit**: Apple's cryptography framework for HMAC operations
- **CommonCrypto**: Legacy C-based crypto library for PBKDF2 implementation

## Implementation Details

### 1. Signature Generation Flow

#### Step 1: Prepare Input Data
```swift
// For file-based signing
let sortedFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
var data = Data()
for file in sortedFiles {
    var fileData = try Data(contentsOf: file)
    // Base64 encode specific file types
    if isSmileIDFile(file) {
        fileData = fileData.base64EncodedData()
    }
    data.append(fileData)
}

// For header and payload signing
var data = Data()
// Filter and serialize headers
if let headers = headers {
    let filteredHeaders = headers
        .mapKeys { $0.lowercased() }
        .filter { $0.key.hasPrefix("smileid-") }
    data += JSONSerialization.data(withJSONObject: filteredHeaders, 
                                   options: [.sortedKeys, .withoutEscapingSlashes])
}
// Append payload
if let payload = payload {
    data += payload
}
```

#### Step 2: Generate Salt
```swift
let salt = String(data.count) + timestamp
let saltData = salt.data(using: .utf8)!
```

#### Step 3: Derive Key using PBKDF2
```swift
func deriveKey(salt: Data, password: String, keyLength: Int = 32, iterations: Int = 200_000) -> SymmetricKey {
    let derivedKey = Data(repeating: 0, count: keyLength)
    CCKeyDerivationPBKDF(
        CCPBKDFAlgorithm(kCCPBKDF2),           // Algorithm: PBKDF2
        password,                               // Password string
        passwordData.count,                     // Password length
        saltPointer,                           // Salt bytes
        salt.count,                            // Salt length
        CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256), // PRF: HMAC-SHA256
        UInt32(iterations),                    // Iteration count: 200,000
        derivedKeyPointer,                     // Output buffer
        keyLength                              // Output length: 32 bytes
    )
    return SymmetricKey(data: derivedKey)
}
```

#### Step 4: Compute HMAC
```swift
func computeHmac(key: SymmetricKey, data: Data) -> HMAC<SHA256>.MAC {
    var hmac = HMAC<SHA256>(key: key)
    hmac.update(data: data)
    return hmac.finalize()
}
```

#### Step 5: Encode Result
```swift
let mac = computeHmac(key: key, data: data)
return Data(mac).base64EncodedString()
```

### 2. Request Integration

#### JSON Requests (POST/GET)
```swift
// In ServiceRunnable.createRestRequest
let timestamp = Date().toISO8601WithMilliseconds()
headers.append(.requestTimestamp(value: timestamp))

// After encoding payload
let requestMac = try? SmileIDCryptoManager.shared.sign(
    timestamp: timestamp,
    headers: headers.toDictionary(),
    payload: payload
)
if let requestMac = requestMac {
    headers.append(.requestMac(value: requestMac))
}
```

#### Multipart Requests
```swift
// Special handling for multipart/form-data
let selfieRequest = SelfieRequest(/* ... */)
let payload = try encoder.encode(selfieRequest)
let requestMac = try? SmileIDCryptoManager.shared.sign(
    timestamp: timestamp,
    headers: headers.toDictionary(),
    payload: payload
)
```

### 3. Header Structure

The following headers participate in the signing process:
- `SmileID-Partner-ID`: Partner identifier
- `SmileID-Request-Signature`: Legacy signature (for multipart)
- `SmileID-Timestamp`: Request timestamp
- `SmileID-Source-SDK`: SDK platform identifier
- `SmileID-Source-SDK-Version`: SDK version
- `SmileID-Request-Timestamp`: ISO8601 timestamp with milliseconds
- `SmileID-Request-Mac`: The computed MAC (output)

### 4. Timestamp Format

Timestamps use ISO8601 format with millisecond precision in UTC:
```swift
// Format: yyyy-MM-dd'T'HH:mm:ss.SSS'Z'
// Example: 2025-02-03T12:34:56.789Z
extension Date {
    func toISO8601WithMilliseconds() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}
```

## Security Considerations

### 1. Secret Management
- The secret is embedded in the SmileIDSecurity framework bundle
- Located at: `SmileIDSecurity.bundle/SECRET`
- The secret file is read at runtime and trimmed of whitespace
- **Critical**: The SECRET file must be protected in the build process

### 2. Salt Generation
- Salt uniqueness is ensured by combining:
  - Payload size (prevents length extension attacks)
  - Timestamp (ensures temporal uniqueness)
- Format: `{payloadSize}{timestamp}`

### 3. Key Derivation Parameters
- **Algorithm**: PBKDF2 with HMAC-SHA256
- **Iterations**: 200,000 (high iteration count for brute-force resistance)
- **Key Length**: 32 bytes (256 bits)

### 4. Error Handling
- Signing failures are silently handled (logged for future Sentry integration)
- Backend will reject requests with missing/invalid MACs
- No sensitive information is exposed in error messages

## Integration Guide

### 1. Basic Setup

Add the SmileIDSecurity dependency to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/smileidentity/smile-id-security", from: "1.0.1")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "SmileIDSecurity", package: "smile-id-security")
        ]
    )
]
```

### 2. Implementing Payload Signing

For a custom implementation, follow these steps:

```swift
// 1. Initialize the crypto manager
let cryptoManager = SmileIDCryptoManager.shared

// 2. Prepare your request
let timestamp = Date().toISO8601WithMilliseconds()
let headers = [
    "SmileID-Partner-ID": "your-partner-id",
    "SmileID-Request-Timestamp": timestamp,
    // ... other headers
]
let payload = try JSONEncoder().encode(yourRequestObject)

// 3. Generate the MAC
let mac = try cryptoManager.sign(
    timestamp: timestamp,
    headers: headers,
    payload: payload
)

// 4. Add MAC to headers
headers["SmileID-Request-Mac"] = mac

// 5. Send the request with signed headers
```

### 3. File Signing

For file-based operations (e.g., document upload):

```swift
let files = [
    URL(fileURLWithPath: "si_selfie_123.jpg"),
    URL(fileURLWithPath: "si_liveness_1.jpg"),
    URL(fileURLWithPath: "si_document_front.jpg")
]

let timestamp = Date().toISO8601WithMilliseconds()
let mac = try cryptoManager.sign(timestamp: timestamp, files: files)

// Include in security_info JSON
let securityInfo = SecurityInfo(timestamp: timestamp, mac: mac)
```

## Testing & Verification

### 1. Unit Testing

Test the signing mechanism:
```swift
func testSignatureGeneration() throws {
    let timestamp = "2025-01-01T00:00:00.000Z"
    let headers = ["smileid-test": "value"]
    let payload = "test payload".data(using: .utf8)!
    
    let signature = try SmileIDCryptoManager.shared.sign(
        timestamp: timestamp,
        headers: headers,
        payload: payload
    )
    
    XCTAssertFalse(signature.isEmpty)
    // Verify base64 format
    XCTAssertNotNil(Data(base64Encoded: signature))
}
```

### 2. Integration Testing

Verify end-to-end request signing:
```swift
func testRequestWithMAC() async throws {
    // Create a test request
    let response = try await service.post(
        to: .testEndpoint,
        with: TestPayload()
    )
    
    // Verify the request included MAC header
    // This would be verified server-side
}
```

### 3. Verification Checklist

- [ ] SECRET file is properly bundled
- [ ] Timestamps are in correct ISO8601 format
- [ ] Headers are properly filtered (only `smileid-` prefixed)
- [ ] JSON serialization uses sorted keys
- [ ] Base64 encoding is applied to specific file types
- [ ] MAC header is included in all authenticated requests

## Troubleshooting

### Common Issues

1. **Missing MAC Header**
   - Verify SmileIDSecurity bundle is included
   - Check SECRET file exists and is readable
   - Ensure timestamp is properly formatted

2. **Invalid Signature**
   - Verify header filtering (lowercase, smileid- prefix)
   - Check JSON serialization options (.sortedKeys, .withoutEscapingSlashes)
   - Ensure payload hasn't been modified after signing

3. **Backend Rejection**
   - Confirm timestamp is recent (within allowed window)
   - Verify all required headers are included
   - Check secret key synchronization with backend

### Debug Logging

Enable verbose logging for troubleshooting:
```swift
// Future implementation with Sentry
if let error = signingError {
    print("Signing failed: \(error)")
    print("Headers: \(headers)")
    print("Payload size: \(payload?.count ?? 0)")
}
```

## Appendix

### A. File Type Detection

SmileID-specific files requiring base64 encoding:
- `si_selfie*` - Selfie images
- `si_liveness*` - Liveness check images
- `si_document_front*` - Document front images
- `si_document_back*` - Document back images

### B. Cryptographic Constants

- **PBKDF2 Iterations**: 200,000
- **Key Length**: 32 bytes
- **Hash Function**: SHA-256
- **Encoding**: Base64 (standard, no URL-safe variant)

### C. Future Enhancements

1. **Sentry Integration**: Comprehensive error tracking
2. **Key Rotation**: Support for multiple secret versions
3. **Performance Optimization**: Caching derived keys for same salt
4. **Audit Logging**: Track all signing operations

---

This documentation represents the complete technical specification for the SmileID SDK payload signing feature. For questions or clarifications, please refer to the SmileID SDK team.