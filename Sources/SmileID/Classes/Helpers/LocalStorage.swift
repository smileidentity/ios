import Foundation
import Zip

public class LocalStorage {
    private static let defaultFolderName = "SmileID"
    private static let unsubmittedFolderName = "unsubmitted"
    private static let submittedFolderName = "submitted"
    private static let fileManager = FileManager.default
    private static let previewImageName = "PreviewImage.jpg"
    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()

    static var defaultDirectory: URL {
        get throws {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return documentDirectory.appendingPathComponent(defaultFolderName)
        }
    }

    static var unsubmittedJobDirectory: URL {
        get throws {
            try defaultDirectory.appendingPathComponent(unsubmittedFolderName)
        }
    }

    static var submittedJobDirectory: URL {
        get throws {
            try defaultDirectory.appendingPathComponent(submittedFolderName)
        }
    }

    private static func createSmileFile(
        to folder: String,
        name: String,
        file data: Data
    ) throws -> URL {
        try createDirectory(at: unsubmittedJobDirectory)
        let destinationFolder = try unsubmittedJobDirectory.appendingPathComponent(folder)
        return try write(data, to: destinationFolder.appendingPathComponent(name))
    }

    private static func filename(for name: String) -> String {
        "\(name)_\(Date().millisecondsSince1970).jpg"
    }

    static func createSelfieFile(
        jobId: String,
        selfieFile data: Data
    ) throws -> URL {
        return try createSmileFile(to: jobId, name: filename(for: FileType.selfie.name), file: data)
    }

    static func createLivenessFile(
        jobId: String,
        livenessFile data: Data
    ) throws -> URL {
        return try createSmileFile(to: jobId, name: filename(for: FileType.liveness.name), file: data)
    }

    static func createDocumentFile(
        jobId: String,
        fileType: FileType,
        document data: Data
    ) throws -> URL {
        return try createSmileFile(to: jobId, name: filename(for: fileType.name), file: data)
    }

    static func getFileByType(
        jobId: String,
        fileType: FileType
    ) throws -> URL? {
        let contents = try getDirectoryContents(jobId: jobId)
        return contents.first(where: { $0.lastPathComponent.contains(fileType.name) })!
    }

    static func getFilesByType(
        jobId: String,
        fileType: FileType
    ) throws -> [URL]? {
        let contents = try getDirectoryContents(jobId: jobId)
        return contents.filter { $0.lastPathComponent.contains(fileType.name) }
    }

    static func createInfoJsonFile(
        jobId: String,
        idInfo: IdInfo? = nil,
        documentFront: URL? = nil,
        documentBack: URL? = nil,
        selfie: URL? = nil,
        livenessImages: [URL]? = nil
    ) throws -> URL {
        var imageInfoArray = [UploadImageInfo]()
        if let selfie = selfie {
            imageInfoArray.append(UploadImageInfo(
                imageTypeId: .selfieJpgFile,
                fileName: selfie.lastPathComponent
            ))

        }
        if let livenessImages = livenessImages {
            let livenessImageInfos = livenessImages.map { liveness in
                return UploadImageInfo(
                    imageTypeId: .livenessJpgFile,
                    fileName: liveness.lastPathComponent
                )
            }
            imageInfoArray.append(contentsOf: livenessImageInfos)
        }
        if let documentFront = documentFront {
            imageInfoArray.append(UploadImageInfo(
                imageTypeId: .idCardJpgFile,
                fileName: documentFront.lastPathComponent
            ))
        }
        if let documentBack = documentBack {
            imageInfoArray.append(UploadImageInfo(
                imageTypeId: .idCardRearJpgFile,
                fileName: documentBack.lastPathComponent
            ))
        }
        let data = try jsonEncoder.encode(UploadRequest(
            images: imageInfoArray,
            idInfo: idInfo
        ))
        return try createSmileFile(to: jobId, name: "info.json", file: data)
    }

    static func getInfoJsonFile(
        jobId: String
    ) throws -> URL {
        let contents = try getDirectoryContents(jobId: jobId)
        return contents.first(where: { $0.lastPathComponent == "info.json" })!
    }

    private static func createPrepUploadFile(
        jobId: String,
        prepUpload: PrepUploadRequest
    ) throws -> URL {
        let data = try jsonEncoder.encode(prepUpload)
        return try createSmileFile(to: jobId, name: "prep_upload.json", file: data)
    }

    static func fetchPrepUploadFile(
        jobId: String
    ) throws -> PrepUploadRequest {
        let contents = try getDirectoryContents(jobId: jobId)
        let preupload = contents.first(where: { $0.lastPathComponent == "prep_upload.json" })
        let data = try Data(contentsOf: preupload!)
        return try jsonDecoder.decode(PrepUploadRequest.self, from: data)
    }

    private static func createAuthenticationRequestFile(
        jobId: String,
        authentationRequest: AuthenticationRequest
    ) throws -> URL {
        let data = try jsonEncoder.encode(authentationRequest)
        return try createSmileFile(to: jobId, name: "authentication_request.json", file: data)
    }

    static func fetchAuthenticationRequestFile(
        jobId: String
    ) throws -> AuthenticationRequest {
        let contents = try getDirectoryContents(jobId: jobId)
        let authenticationrequest = contents.first(where: { $0.lastPathComponent == "authentication_request.json" })
        let data = try Data(contentsOf: authenticationrequest!)
        return try jsonDecoder.decode(AuthenticationRequest.self, from: data)
    }

    static func fetchUploadZip(
        jobId: String
    ) throws -> Data {
        let contents = try getDirectoryContents(jobId: jobId)
        let zipUrl = contents.first(where: { $0.lastPathComponent == "upload.zip" })
        return try Data(contentsOf: zipUrl!)
    }

    static func saveOfflineJob(
        jobId: String,
        userId: String,
        jobType: JobType,
        enrollment: Bool,
        allowNewEnroll: Bool,
        partnerParams: [String: String]
    ) throws {
        do {
            _ = try createPrepUploadFile(
                jobId: jobId,
                prepUpload: PrepUploadRequest(
                    partnerParams: PartnerParams(
                        jobId: jobId,
                        userId: userId,
                        jobType: jobType,
                        extras: partnerParams
                    ),
                    allowNewEnroll: String(allowNewEnroll),
                    timestamp: "", // remove this so it is not stored offline
                    signature: "" // remove this so it is not stored offline
                )
            )
            _ = try createAuthenticationRequestFile(
                jobId: jobId,
                authentationRequest: AuthenticationRequest(
                    jobType: jobType,
                    enrollment: enrollment,
                    jobId: jobId,
                    userId: userId,
                    authToken: "" // remove this so it is not stored offline
                )
            )
        }
    }

    private static func write(_ data: Data, to url: URL, options completeFileProtection: Bool = true) throws -> URL {
        let directoryURL = url.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        if !fileManager.fileExists(atPath: url.relativePath) {
            try data.write(to: url, options: completeFileProtection ? .completeFileProtection : [])
            return url
        } else {
            try fileManager.removeItem(atPath: url.relativePath)
            try data.write(to: url, options: completeFileProtection ? .completeFileProtection : [])
            return url
        }
    }

    private static func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static func getDirectoryContents(
        jobId: String
    ) throws -> [URL] {
        let folderPathURL = try unsubmittedJobDirectory.appendingPathComponent(jobId)
        return try fileManager.contentsOfDirectory(at: folderPathURL, includingPropertiesForKeys: nil)
    }

    static func getUnsubmittedJobs() -> [String] {
        do {
            return try fileManager.contentsOfDirectory(atPath: unsubmittedJobDirectory.relativePath)
        } catch {
            print("Error fetching unsubmitted jobs: \(error.localizedDescription)")
            return []
        }
    }

    static func getSubmittedJobs() -> [String] {
        do {
            return try fileManager.contentsOfDirectory(atPath: submittedJobDirectory.relativePath)
        } catch {
            print("Error fetching submitted jobs: \(error.localizedDescription)")
            return []
        }
    }

    static func moveToSubmittedJobs(jobId: String) throws {
        try createDirectory(at: submittedJobDirectory)
        let unsubmittedFileDirectory = try unsubmittedJobDirectory.appendingPathComponent(jobId)
        let submittedFileDirectory = try submittedJobDirectory.appendingPathComponent(jobId)
        try fileManager.moveItem(at: unsubmittedFileDirectory, to: submittedFileDirectory)
    }

    static func handleOfflineJobFailure(
        jobId: String,
        error: Error
    ) throws {
        if !SmileID.allowOfflineMode {
            return try LocalStorage.moveToSubmittedJobs(jobId: jobId)
        }
    }

    // todo - rework this as we change zip library
    public static func toZip(
        uploadRequest: UploadRequest,
        to folder: String = "sid-\(UUID().uuidString)"
    ) throws -> URL {
        try createDirectory(at: defaultDirectory)
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        let jsonData = try jsonEncoder.encode(uploadRequest)
        let jsonUrl = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        let imageUrls = uploadRequest.images.map { imageInfo in
            destinationFolder.appendingPathComponent(imageInfo.fileName)
        }
        return try zipFiles(at: [jsonUrl] + imageUrls)
    }

    public static func zipFiles(at urls: [URL]) throws -> URL {
        try Zip.quickZipFiles(urls, fileName: "upload")
    }

    private static func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.relativePath) {
            try fileManager.removeItem(atPath: url.relativePath)
        }
    }

    static func delete(at jobIds: [String]) throws {
        try jobIds.forEach {
            let unsubmittedJob = try unsubmittedJobDirectory.appendingPathComponent($0)
            try delete(at: unsubmittedJob)
            let submittedJob = try submittedJobDirectory.appendingPathComponent($0)
            try delete(at: submittedJob)
        }
    }

    static func deleteAll() throws {
        if fileManager.fileExists(atPath: try defaultDirectory.relativePath) {
            try fileManager.removeItem(atPath: defaultDirectory.relativePath)
        }
    }
}

public extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
