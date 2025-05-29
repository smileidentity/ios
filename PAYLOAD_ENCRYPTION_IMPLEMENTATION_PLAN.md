# SmileID SDK Payload Encryption Implementation Plan

## Executive Summary

This document outlines the implementation plan for adding payload encryption to the SmileID SDK. The encryption will prevent request payload inspection through proxy tools while maintaining backward compatibility and ensuring secure decryption on the backend.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Encryption Design](#encryption-design)
3. [SmileIDCryptoManager Enhancements](#smileidcryptomanager-enhancements)
4. [SDK Integration Points](#sdk-integration-points)
5. [Implementation Phases](#implementation-phases)
6. [Security Considerations](#security-considerations)
7. [Performance Optimization](#performance-optimization)
8. [Testing Strategy](#testing-strategy)
9. [Migration Strategy](#migration-strategy)
10. [Code Improvements](#code-improvements)

## Architecture Overview

### High-Level Flow

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   Application       │     │  SmileID SDK         │     │   Backend Server    │
│                     │────▶│                      │────▶│                     │
│  - Raw Payload      │     │  - Encrypt Payload   │     │  - Decrypt Payload  │
│                     │     │  - Add Metadata      │     │  - Process Request  │
└─────────────────────┘     └──────────────────────┘     └─────────────────────┘
```

### Encryption Flow

```
Raw Payload → Derive Encryption Key → Generate IV → Encrypt (AES-GCM) → Base64 Encode → Send
                        ↑
                    PBKDF2 Key
                  (from SECRET)
```

## Encryption Design

### Algorithm Selection

**Primary Choice: AES-256-GCM**
- **Rationale**: 
  - Authenticated encryption (provides both confidentiality and integrity)
  - Hardware acceleration on iOS devices
  - Built-in authentication tag prevents tampering
  - Industry standard with proven security

### Request Type Encryption Strategies

Different request types require different encryption approaches:

#### 1. REST JSON Requests
- **What to encrypt**: Entire JSON payload
- **Content-Type**: Changes from `application/json` to `application/octet-stream`
- **Examples**: Enhanced KYC, Authentication, PrepUpload requests
- **Encryption**: Full payload encryption with metadata envelope

#### 2. Multipart Form Requests
- **What to encrypt**: Only sensitive metadata fields (partner_params, metadata)
- **What NOT to encrypt**: Image data (already compressed, minimal security benefit)
- **Content-Type**: Remains `multipart/form-data`
- **Examples**: SmartSelfie enrollment/authentication
- **Encryption**: Field-level encryption with base64 encoding in multipart

#### 3. ZIP File Uploads
- **What to encrypt**: Entire ZIP file
- **Content-Type**: Changes from `application/zip` to `application/octet-stream`
- **Examples**: Document verification uploads to S3
- **Special consideration**: S3 uploads may need to remain unencrypted (configurable)

### Key Management

1. **Key Derivation**:
   - Reuse existing PBKDF2 implementation
   - Derive separate keys for encryption and MAC
   - Key separation using context strings

2. **Key Hierarchy**:
   ```
   SECRET (from SmileIDSecurity bundle)
        │
        ├─── PBKDF2 ──→ Master Key (32 bytes)
        │                    │
        │                    ├─── HKDF-Expand ──→ Encryption Key (32 bytes)
        │                    └─── HKDF-Expand ──→ MAC Key (32 bytes)
        │
        └─── Salt: timestamp + request_id
   ```

### Metadata Structure

Each encrypted payload will include:
```json
{
  "version": "1.0",
  "algorithm": "AES-256-GCM",
  "iv": "base64_encoded_iv",
  "auth_tag": "base64_encoded_tag",
  "encrypted_data": "base64_encoded_ciphertext",
  "timestamp": "2025-01-01T00:00:00.000Z"
}
```

## SmileIDCryptoManager Enhancements

### New Error Cases

```swift
public enum SmileIDCryptoError: Error {
    // Existing cases
    case deriveKeyError
    case encodingError
    case cantReadSecretValueError
    
    // New cases
    case encryptionError(String)
    case decryptionError(String)
    case invalidKeyLength
    case invalidIVLength
    case authenticationTagMismatch
}
```

### New Public Methods

```swift
public extension SmileIDCryptoManager {
    
    /// Encrypts payload data using AES-256-GCM
    /// - Parameters:
    ///   - payload: The data to encrypt
    ///   - timestamp: Request timestamp for key derivation
    ///   - requestId: Unique request identifier for salt generation
    /// - Returns: Encrypted payload with metadata
    /// - Throws: SmileIDCryptoError if encryption fails
    func encryptPayload(
        _ payload: Data,
        timestamp: String,
        requestId: String = UUID().uuidString
    ) throws -> Data
    
    /// Decrypts payload data (for testing/verification)
    /// - Parameters:
    ///   - encryptedData: The encrypted payload with metadata
    ///   - timestamp: Request timestamp used during encryption
    ///   - requestId: Request identifier used during encryption
    /// - Returns: Decrypted payload data
    /// - Throws: SmileIDCryptoError if decryption fails
    func decryptPayload(
        _ encryptedData: Data,
        timestamp: String,
        requestId: String
    ) throws -> Data
}
```

### New Private Methods

```swift
private extension SmileIDCryptoManager {
    
    /// Derives separate encryption and MAC keys using HKDF-Expand
    func deriveEncryptionKeys(
        masterKey: SymmetricKey,
        context: String
    ) throws -> (encryptionKey: SymmetricKey, macKey: SymmetricKey)
    
    /// Generates cryptographically secure IV
    func generateIV() throws -> Data
    
    /// Performs AES-GCM encryption
    func encryptAESGCM(
        data: Data,
        key: SymmetricKey,
        iv: Data
    ) throws -> (ciphertext: Data, authTag: Data)
    
    /// Creates encrypted payload envelope
    func createEncryptedEnvelope(
        ciphertext: Data,
        iv: Data,
        authTag: Data,
        timestamp: String
    ) throws -> Data
}
```

### Enhanced Implementation

```swift
public func encryptPayload(
    _ payload: Data,
    timestamp: String,
    requestId: String = UUID().uuidString
) throws -> Data {
    // 1. Generate salt combining timestamp and requestId
    let salt = "\(timestamp):\(requestId)".data(using: .utf8)!
    
    // 2. Derive master key
    let masterKey = try deriveKey(
        salt: salt,
        password: getSecretPassword(),
        keyLength: 32,
        iterations: 200_000
    )
    
    // 3. Derive encryption and MAC keys
    let (encryptionKey, _) = try deriveEncryptionKeys(
        masterKey: masterKey,
        context: "SmileID-Encryption-v1"
    )
    
    // 4. Generate IV
    let iv = try generateIV()
    
    // 5. Encrypt payload
    let (ciphertext, authTag) = try encryptAESGCM(
        data: payload,
        key: encryptionKey,
        iv: iv
    )
    
    // 6. Create encrypted envelope
    return try createEncryptedEnvelope(
        ciphertext: ciphertext,
        iv: iv,
        authTag: authTag,
        timestamp: timestamp
    )
}

private func encryptAESGCM(
    data: Data,
    key: SymmetricKey,
    iv: Data
) throws -> (ciphertext: Data, authTag: Data) {
    guard iv.count == 12 else {
        throw SmileIDCryptoError.invalidIVLength
    }
    
    do {
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        guard let ciphertext = sealedBox.ciphertext,
              let tag = sealedBox.tag else {
            throw SmileIDCryptoError.encryptionError("Failed to extract ciphertext or tag")
        }
        
        return (Data(ciphertext), Data(tag))
    } catch {
        throw SmileIDCryptoError.encryptionError(error.localizedDescription)
    }
}
```

## SDK Integration Points

The SmileID SDK uses three different request types that need encryption support:

### Request Types Overview

1. **REST JSON Requests**: Standard JSON payloads (Enhanced KYC, Authentication, etc.)
2. **Multipart Form Requests**: SmartSelfie with images and metadata
3. **PrepUpload/Upload Flow**: Document verification with ZIP file uploads

### 1. REST JSON Request Encryption

Modify the `createRestRequest` method to support encryption:

```swift
extension ServiceRunnable {
    
    private func createRestRequest<T: Encodable>(
        path: PathType,
        method: RestMethod,
        headers: [HTTPHeader],
        queryParameters: [HTTPQueryParameters]? = nil,
        body: T
    ) async throws -> RestRequest {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            throw URLError(.badURL)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let payload = try encoder.encode(body)
        
        var finalPayload = payload
        var signedHeaders = headers
        
        // Check if encryption should be applied
        if shouldEncryptRequest(path: path, headers: headers) {
            let timestamp = headers.first { $0.name == "SmileID-Request-Timestamp" }?.value 
                ?? Date().toISO8601WithMilliseconds()
            let requestId = UUID().uuidString
            
            // Encrypt the payload
            finalPayload = try SmileIDCryptoManager.shared.encryptPayload(
                payload,
                timestamp: timestamp,
                requestId: requestId
            )
            
            // Add encryption headers
            signedHeaders.append(.encryptionVersion(value: "1.0"))
            signedHeaders.append(.requestId(value: requestId))
            signedHeaders.append(.contentEncrypted(value: "true"))
            
            // Change content type
            signedHeaders.removeAll { $0.name == "Content-Type" }
            signedHeaders.append(.contentType(value: "application/octet-stream"))
        }
        
        // Sign the payload (encrypted or not)
        if let header = headers.first(where: { $0.name == "SmileID-Request-Timestamp" }) {
            let requestMac = try? SmileIDCryptoManager.shared.sign(
                timestamp: header.value,
                headers: signedHeaders.toDictionary(),
                payload: finalPayload
            )
            if let requestMac = requestMac {
                signedHeaders.append(.requestMac(value: requestMac))
            }
        }
        
        let request = RestRequest(
            url: url,
            method: method,
            headers: signedHeaders,
            queryParameters: queryParameters,
            body: finalPayload
        )
        return request
    }
}
```

### 2. Multipart Form Request Encryption

For multipart requests, we need to encrypt the JSON metadata within the multipart body:

```swift
extension ServiceRunnable {
    
    func multipart(
        to path: PathType,
        signature: String,
        timestamp: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        // ... other parameters ...
    ) async throws -> SmartSelfieResponse {
        // ... existing header setup ...
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        // Create the SelfieRequest object
        let selfieRequest = SelfieRequest(
            selfieImage: selfieImage.data,
            livenessImages: livenessImages.map { $0.data },
            userId: userId,
            partnerParams: partnerParams,
            // ... other fields ...
        )
        
        let payload = try encoder.encode(selfieRequest)
        
        // Check if we should encrypt multipart metadata
        if shouldEncryptMultipartMetadata(path: path) {
            // Encrypt sensitive fields in multipart
            let encryptedPartnerParams = try encryptMultipartField(
                partnerParams,
                timestamp: timestamp,
                fieldName: "partner_params"
            )
            let encryptedMetadata = try encryptMultipartField(
                metadata.items,
                timestamp: timestamp,
                fieldName: "metadata"
            )
            
            // Update multipart creation with encrypted fields
            let request = try await createMultiPartRequest(
                url: path,
                method: .post,
                headers: headers,
                uploadData: createEncryptedMultiPartRequestData(
                    selfieImage: selfieImage,
                    livenessImages: livenessImages,
                    encryptedPartnerParams: encryptedPartnerParams,
                    encryptedMetadata: encryptedMetadata,
                    // ... other parameters ...
                    boundary: boundary
                )
            )
        } else {
            // Use existing multipart creation
            // ... existing code ...
        }
        
        return try await serviceClient.multipart(request: request)
    }
    
    private func encryptMultipartField<T: Encodable>(
        _ field: T?,
        timestamp: String,
        fieldName: String
    ) throws -> Data? {
        guard let field = field else { return nil }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let fieldData = try encoder.encode(field)
        
        return try SmileIDCryptoManager.shared.encryptPayload(
            fieldData,
            timestamp: timestamp,
            requestId: "\(UUID().uuidString):\(fieldName)"
        )
    }
}
```

### 3. PrepUpload/Upload Flow Encryption

The document verification flow has two stages that need different handling:

#### Stage 1: PrepUpload Request (JSON)
```swift
// This uses standard REST JSON encryption
let prepUploadRequest = PrepUploadRequest(...)
// Will be encrypted using createRestRequest method above
```

#### Stage 2: ZIP File Upload
```swift
extension ServiceRunnable {
    
    func upload(
        data: Data,
        to url: String,
        with restMethod: RestMethod
    ) async throws -> Data {
        var uploadData = data
        var headers: [HTTPHeader] = [.contentType(value: "application/zip")]
        
        // Check if we should encrypt ZIP files
        if shouldEncryptUpload(url: url) {
            let timestamp = Date().toISO8601WithMilliseconds()
            let requestId = UUID().uuidString
            
            // Encrypt the entire ZIP file
            uploadData = try SmileIDCryptoManager.shared.encryptPayload(
                data,
                timestamp: timestamp,
                requestId: requestId
            )
            
            // Update headers for encrypted content
            headers = [
                .contentType(value: "application/octet-stream"),
                .encryptionVersion(value: "1.0"),
                .requestId(value: requestId),
                .contentEncrypted(value: "true"),
                .requestTimestamp(value: timestamp)
            ]
            
            // Sign the encrypted upload
            let requestMac = try? SmileIDCryptoManager.shared.sign(
                timestamp: timestamp,
                headers: headers.toDictionary(),
                payload: uploadData
            )
            if let requestMac = requestMac {
                headers.append(.requestMac(value: requestMac))
            }
        }
        
        let uploadRequest = RestRequest(
            url: URL(string: url)!,
            method: restMethod,
            headers: headers,
            body: uploadData
        )
        
        return try await serviceClient.upload(request: uploadRequest)
    }
}
```

### 4. Request Type Detection

Add logic to determine which requests should be encrypted:

```swift
extension ServiceRunnable {
    
    private func shouldEncryptRequest(path: String, headers: [HTTPHeader]) -> Bool {
        // Check global config
        guard SmileID.config.enablePayloadEncryption else { return false }
        
        // Check excluded paths
        if SmileID.config.encryptionExcludedPaths.contains(path) {
            return false
        }
        
        // Check for opt-out header
        if headers.contains(where: { $0.name == "SmileID-Skip-Encryption" }) {
            return false
        }
        
        return true
    }
    
    private func shouldEncryptMultipartMetadata(path: PathType) -> Bool {
        guard SmileID.config.enablePayloadEncryption else { return false }
        
        // Only encrypt metadata fields, not image data
        return SmileID.config.encryptMultipartMetadata
    }
    
    private func shouldEncryptUpload(url: String) -> Bool {
        guard SmileID.config.enablePayloadEncryption else { return false }
        
        // Check if URL is S3 or internal
        if url.contains("s3.amazonaws.com") {
            return SmileID.config.encryptS3Uploads
        }
        
        return true
    }
}
```

### 5. New HTTPHeader Extensions

```swift
public extension HTTPHeader {
    static func encryptionVersion(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Encryption-Version", value: value)
    }
    
    static func requestId(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Request-ID", value: value)
    }
    
    static func contentEncrypted(value: String) -> HTTPHeader {
        HTTPHeader(name: "SmileID-Content-Encrypted", value: value)
    }
    
    static func skipEncryption() -> HTTPHeader {
        HTTPHeader(name: "SmileID-Skip-Encryption", value: "true")
    }
}
```

### 6. Configuration Updates

Add comprehensive encryption configuration to SmileID:

```swift
public struct Config: Codable {
    // ... existing properties ...
    
    /// Enable payload encryption for all requests
    public var enablePayloadEncryption: Bool = false
    
    /// Endpoints to exclude from encryption (for backward compatibility)
    public var encryptionExcludedPaths: Set<String> = []
    
    /// Enable encryption for multipart metadata fields
    public var encryptMultipartMetadata: Bool = true
    
    /// Enable encryption for S3 uploads
    public var encryptS3Uploads: Bool = false
    
    /// Encryption algorithm version
    public var encryptionVersion: String = "1.0"
}
```

### 7. Multipart Encryption Helper

Create a helper for encrypted multipart data:

```swift
extension ServiceRunnable {
    
    func createEncryptedMultiPartRequestData(
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        encryptedPartnerParams: Data?,
        encryptedMetadata: Data?,
        userId: String?,
        callbackUrl: String?,
        sandboxResult: Int?,
        allowNewEnroll: Bool?,
        failureReason: FailureReason?,
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()
        
        // Append encrypted partner params if available
        if let encryptedParams = encryptedPartnerParams {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"partner_params_encrypted\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Transfer-Encoding: base64\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(encryptedParams.base64EncodedData())
            body.append(lineBreak.data(using: .utf8)!)
        }
        
        // Append encrypted metadata if available
        if let encryptedMeta = encryptedMetadata {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"metadata_encrypted\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Transfer-Encoding: base64\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(encryptedMeta.base64EncodedData())
            body.append(lineBreak.data(using: .utf8)!)
        }
        
        // Add non-encrypted fields (userId, callbackUrl, etc.)
        // ... existing multipart code for these fields ...
        
        // Images remain unencrypted (already compressed)
        // ... existing image handling code ...
        
        return body
    }
}

## Implementation Phases

### Phase 1: Core Encryption (Week 1-2)
1. Implement encryption/decryption methods in SmileIDCryptoManager
2. Add unit tests for all cryptographic operations
3. Verify compatibility with CryptoKit on iOS 13+

### Phase 2: SDK Integration (Week 2-3)
1. Integrate encryption into ServiceRunnable
2. Add configuration options
3. Update headers and request handling
4. Test with mock endpoints

### Phase 3: Backend Coordination (Week 3-4)
1. Coordinate with backend team for decryption implementation
2. Test end-to-end encryption/decryption
3. Performance testing and optimization

### Phase 4: Migration & Rollout (Week 4-5)
1. Feature flag implementation
2. Gradual rollout strategy
3. Monitoring and metrics
4. Documentation updates

## Security Considerations

### 1. Key Security
- Never log or expose encryption keys
- Use secure key derivation with high iteration count
- Implement key rotation mechanism for future

### 2. IV/Nonce Management
- Always use unique IV for each encryption
- Use cryptographically secure random generation
- 96-bit IV for GCM mode (12 bytes)

### 3. Authentication
- GCM provides built-in authentication tag
- Verify tag on backend before decryption
- Continue using MAC for request integrity

### 4. Error Handling
- Don't expose detailed crypto errors to users
- Log securely for debugging
- Graceful fallback for encryption failures

### 5. Threat Model Considerations
- **Proxy Inspection**: Encrypted payload prevents content inspection
- **Man-in-the-Middle**: TLS + encryption provides defense in depth
- **Replay Attacks**: Timestamp validation prevents replays
- **Tampering**: GCM authentication tag detects modifications

## Performance Optimization

### 1. Caching Strategy
```swift
private class KeyCache {
    private var cache: [String: (key: SymmetricKey, expiry: Date)] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes
    
    func getKey(for salt: String) -> SymmetricKey? {
        guard let cached = cache[salt],
              cached.expiry > Date() else {
            return nil
        }
        return cached.key
    }
    
    func setKey(_ key: SymmetricKey, for salt: String) {
        cache[salt] = (key, Date().addingTimeInterval(ttl))
    }
}
```

### 2. Async Operations
- Use async/await for encryption operations
- Consider background queue for large payloads
- Implement progress callbacks for UI updates

### 3. Memory Management
- Clear sensitive data after use
- Use autoreleasepool for large operations
- Monitor memory usage during encryption

## Testing Strategy

### 1. Unit Tests
```swift
func testPayloadEncryption() throws {
    let payload = "test data".data(using: .utf8)!
    let timestamp = Date().toISO8601WithMilliseconds()
    
    let encrypted = try cryptoManager.encryptPayload(
        payload,
        timestamp: timestamp
    )
    
    // Verify structure
    let envelope = try JSONDecoder().decode(
        EncryptedEnvelope.self,
        from: encrypted
    )
    
    XCTAssertEqual(envelope.version, "1.0")
    XCTAssertEqual(envelope.algorithm, "AES-256-GCM")
    XCTAssertNotNil(envelope.encryptedData)
}

func testEncryptionDecryptionRoundTrip() throws {
    let originalData = "sensitive payload".data(using: .utf8)!
    let timestamp = Date().toISO8601WithMilliseconds()
    let requestId = UUID().uuidString
    
    let encrypted = try cryptoManager.encryptPayload(
        originalData,
        timestamp: timestamp,
        requestId: requestId
    )
    
    let decrypted = try cryptoManager.decryptPayload(
        encrypted,
        timestamp: timestamp,
        requestId: requestId
    )
    
    XCTAssertEqual(originalData, decrypted)
}
```

### 2. Integration Tests

#### REST JSON Request Tests
```swift
func testEnhancedKycEncryption() async throws {
    SmileID.config.enablePayloadEncryption = true
    
    let request = EnhancedKycRequest(
        country: "NG",
        idType: "BVN",
        idNumber: "12345678901"
    )
    
    let response = try await smileIDService.doEnhancedKyc(request: request)
    
    // Verify request was encrypted (check logs/headers)
    XCTAssertNotNil(response)
}
```

#### Multipart Request Tests
```swift
func testSmartSelfieMultipartEncryption() async throws {
    SmileID.config.enablePayloadEncryption = true
    SmileID.config.encryptMultipartMetadata = true
    
    let selfieImage = MultipartBody(...)
    let response = try await smileIDService.doSmartSelfieEnrollment(
        signature: signature,
        timestamp: timestamp,
        selfieImage: selfieImage,
        livenessImages: livenessImages,
        partnerParams: ["key": "sensitive_value"],
        metadata: metadata
    )
    
    // Verify metadata was encrypted but images were not
    XCTAssertNotNil(response)
}
```

#### Upload Flow Tests
```swift
func testDocumentVerificationUploadEncryption() async throws {
    SmileID.config.enablePayloadEncryption = true
    
    // Stage 1: PrepUpload (JSON encryption)
    let prepUploadResponse = try await smileIDService.prepUpload(request: prepUploadRequest)
    
    // Stage 2: ZIP upload (file encryption)
    let zipData = try createTestZipFile()
    let uploadResponse = try await smileIDService.upload(
        zip: zipData,
        to: prepUploadResponse.uploadUrl
    )
    
    XCTAssertNotNil(uploadResponse)
}
```

### 3. Performance Tests
- Benchmark encryption/decryption times for different payload sizes
- Test multipart encryption overhead
- Compare encrypted vs unencrypted request times
- Memory usage profiling for large ZIP files

## Migration Strategy

### 1. Feature Flag Implementation
```swift
public extension SmileID {
    static var encryptionEnabled: Bool {
        // Check remote config
        if let remoteValue = RemoteConfig.shared.getBool("payload_encryption_enabled") {
            return remoteValue
        }
        // Fall back to local config
        return config.enablePayloadEncryption
    }
}
```

### 2. Gradual Rollout
1. **Phase 1**: Internal testing (0.1% of traffic)
2. **Phase 2**: Beta users (5% of traffic)
3. **Phase 3**: Gradual increase (25%, 50%, 75%)
4. **Phase 4**: Full rollout (100%)

### 3. Rollback Plan
- Feature flag for instant disable
- Backend support for both encrypted/unencrypted
- Client-side fallback mechanism

## Code Improvements

### 1. Current Code Enhancements

#### Error Handling Improvements
```swift
public enum SmileIDCryptoError: LocalizedError {
    case deriveKeyError
    case encodingError
    case cantReadSecretValueError
    case encryptionError(String)
    case decryptionError(String)
    case invalidKeyLength
    case invalidIVLength
    case authenticationTagMismatch
    
    public var errorDescription: String? {
        switch self {
        case .deriveKeyError:
            return "Failed to derive cryptographic key"
        case .encodingError:
            return "Failed to encode data"
        case .cantReadSecretValueError:
            return "Unable to access security configuration"
        case .encryptionError(let detail):
            return "Encryption failed: \(detail)"
        case .decryptionError(let detail):
            return "Decryption failed: \(detail)"
        case .invalidKeyLength:
            return "Invalid key length for encryption"
        case .invalidIVLength:
            return "Invalid initialization vector length"
        case .authenticationTagMismatch:
            return "Authentication verification failed"
        }
    }
}
```

#### Thread Safety
```swift
public class SmileIDCryptoManager {
    private let queue = DispatchQueue(label: "com.smileidentity.crypto", attributes: .concurrent)
    private let keyCache = KeyCache()
    
    public func encryptPayload(
        _ payload: Data,
        timestamp: String,
        requestId: String = UUID().uuidString
    ) throws -> Data {
        return try queue.sync {
            // Thread-safe encryption implementation
        }
    }
}
```

#### Memory Security
```swift
private func clearSensitiveData(_ data: inout Data) {
    data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}
```

### 2. Documentation Improvements
- Add comprehensive inline documentation
- Include usage examples
- Document security considerations
- Add troubleshooting guide

### 3. Logging and Monitoring
```swift
private enum CryptoLogEvent {
    case encryptionStarted(payloadSize: Int)
    case encryptionCompleted(duration: TimeInterval)
    case encryptionFailed(error: Error)
    case keyDerivationCompleted(duration: TimeInterval)
}

private func log(_ event: CryptoLogEvent) {
    #if DEBUG
    // Detailed logging for debug builds
    #else
    // Minimal logging for release builds
    #endif
}
```

## Conclusion

This implementation plan provides a comprehensive approach to adding payload encryption to the SmileID SDK. The design prioritizes security, performance, and backward compatibility while providing a clear migration path. The phased approach allows for thorough testing and gradual rollout, minimizing risk while maximizing security benefits.

### Key Benefits
1. **Enhanced Security**: Prevents payload inspection via proxy tools
2. **Backward Compatible**: Gradual migration with feature flags
3. **Performance Optimized**: Caching and async operations
4. **Future Proof**: Extensible design for algorithm updates

### Next Steps
1. Review and approve the design with security team
2. Coordinate with backend team on decryption implementation
3. Begin Phase 1 implementation
4. Set up testing infrastructure