import Foundation

protocol SmartSelfieSubmissionServiceType {
  func submit(
    jobId: String,
    userId: String,
    isEnroll: Bool,
    allowNewEnroll: Bool,
    selfie: URL,
    liveness: [URL],
    metadata: [Metadatum]
  ) async throws -> SmartSelfieResponse
}

struct SmartSelfieSubmissionService: SmartSelfieSubmissionServiceType {
  func submit(
    jobId: String,
    userId: String,
    isEnroll: Bool,
    allowNewEnroll: Bool,
    selfie: URL,
    liveness: [URL],
    metadata: [Metadatum]
  ) async throws -> SmartSelfieResponse {
    let jobType: JobType = isEnroll ? .smartSelfieEnrollment : .smartSelfieAuthentication
    let authRequest = AuthenticationRequest(
      jobType: jobType,
      enrollment: isEnroll,
      jobId: jobId,
      userId: userId
    )

    // Offline save
    if SmileID.allowOfflineMode {
      try LocalStorage.saveOfflineJob(
        jobId: jobId,
        userId: userId,
        jobType: jobType,
        enrollment: isEnroll,
        allowNewEnroll: allowNewEnroll,
        metadata: metadata,
        partnerParams: [:]
      )
    }

    return try await getExceptionHandler {
      let auth = try await SmileID.api.authenticate(request: authRequest)

      guard let selfieData = try? Data(contentsOf: selfie),
            let selfiePart = MultipartBody(
              withImage: selfieData,
              forName: selfie.lastPathComponent
            ) else {
        throw SmileIDError.unknown("Selfie load failed")
      }

      let livenessParts: [MultipartBody] = liveness.compactMap { url in
        guard let data = try? Data(contentsOf: url) else { return nil }
        return MultipartBody(withImage: data, forName: url.lastPathComponent)
      }
      guard livenessParts.count == 7 else {
        throw SmileIDError.unknown("Missing liveness images")
      }

      if isEnroll {
        return try await SmileID.api.doSmartSelfieEnrollment(
          signature: auth.signature,
          timestamp: auth.timestamp,
          selfieImage: selfiePart,
          livenessImages: livenessParts,
          userId: userId,
          partnerParams: [:],
          callbackUrl: SmileID.callbackUrl,
          sandboxResult: nil,
          allowNewEnroll: allowNewEnroll,
          failureReason: nil
        )
      } else {
        return try await SmileID.api.doSmartSelfieAuthentication(
          signature: auth.signature,
          timestamp: auth.timestamp,
          userId: userId,
          selfieImage: selfiePart,
          livenessImages: livenessParts,
          partnerParams: [:],
          callbackUrl: SmileID.callbackUrl,
          sandboxResult: nil,
          failureReason: nil
        )
      }
    }
  }
}
