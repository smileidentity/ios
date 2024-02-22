@testable import SmileID
import Combine
import XCTest
import Zip

class OrchestratedBiometricKycViewModelTest: XCTestCase {
    var subject: OrchestratedBiometricKycViewModel!
    let mockService = MockSmileIDServiceable.create()
    let jobId = "jobId"
    let userId = "userId"
    let allowNewEnroll = false
    let idInfo = IdInfo(country: "country", idType: "idType")
    let jsonDecoder = JSONDecoder()

    override func setUp() {
        super.setUp()
        initSdk()
        let mockDependency = DependencyContainer()
        DependencyAutoResolver.set(resolver: mockDependency)
        mockDependency.register(SmileIDServiceable.self, creation: {
            self.mockService
        })
        subject = OrchestratedBiometricKycViewModel(
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            idInfo: idInfo
        )
    }

    func testEnteredIsSetToTrue() async throws {
        // given
        let authenticateRequest = AuthenticationRequest(
            jobType: .biometricKyc,
            enrollment: false,
            jobId: jobId,
            userId: userId,
            country: idInfo.country,
            idType: idInfo.idType
        )
        let authResponse = AuthenticationResponse(
            success: true,
            signature: "signature",
            timestamp: "timestamp",
            partnerParams: PartnerParams(
                jobId: jobId,
                userId: userId,
                jobType: .biometricKyc,
                extras: [:]
            )
        )

        let prepUploadRequest = PrepUploadRequest(
            partnerParams: authResponse.partnerParams,
            allowNewEnroll: String(allowNewEnroll),
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        let prepUploadResponse = PrepUploadResponse(
            code: "code",
            refId: "refId",
            uploadUrl: "uploadUrl",
            smileJobId: "smileJobId"
        )

        let uploadResponse = UploadResponse.response(data: nil)

        let jobStatusRequest = JobStatusRequest(
            userId: userId,
            jobId: jobId,
            includeImageLinks: false,
            includeHistory: false,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )
        let jobStatusResponse = JobStatusResponse<BiometricKycJobResult>(jobComplete: true)

        var capturedZip: Data!
        mockService.expect { $0.authenticate(request: authenticateRequest) }
            .returning(just(authResponse))
        mockService.expect { $0.prepUpload(request: prepUploadRequest) }
            .returning(just(prepUploadResponse))
        mockService.expect { $0.getJobStatus(request: jobStatusRequest) }
            .returning(just(jobStatusResponse))
        mockService.expect { $0.upload(zip: Data(), to: prepUploadResponse.uploadUrl) }
            .doing { actionArgs in capturedZip = actionArgs[0] as? Data }
            .returning(just(uploadResponse))

        let selfieCaptureResultStore = SelfieCaptureResultStore(
            selfie: try LocalStorage.saveImage(image: Data(), name: "selfie.jpg"),
            livenessImages: []
        )

        // when
        _ = await subject.submitJob(selfieCaptureResultStore: selfieCaptureResultStore).result

        // then
        // TODO: Refactor this once we have the ability to unzip in-memory
        let capturedZipUrl = try LocalStorage.defaultDirectory.appendingPathComponent("capture.zip")
        try capturedZip.write(to: capturedZipUrl)
        let unzipDir = try Zip.quickUnzipFile(capturedZipUrl)
        let infoJsonPath = unzipDir.appendingPathComponent("info.json")
        let infoJsonString = try Data(contentsOf: infoJsonPath)
        print(infoJsonPath)
        print(infoJsonString)
        let capturedInfoJson = try jsonDecoder.decode(UploadRequest.self, from: infoJsonString)
        XCTAssert(capturedInfoJson.idInfo?.entered == true)
        mockService.verify()
    }
}
