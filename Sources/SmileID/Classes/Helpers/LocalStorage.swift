import Foundation
import ZIPFoundation

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

    public static func createSelfieFile(
        jobId: String,
        selfieFile data: Data
    ) throws -> URL {
        try createSmileFile(to: jobId, name: filename(for: FileType.selfie.name), file: data)
    }

    public static func createLivenessFile(
        jobId: String,
        livenessFile data: Data
    ) throws -> URL {
        try createSmileFile(to: jobId, name: filename(for: FileType.liveness.name), file: data)
    }

    public static func createDocumentFile(
        jobId: String,
        fileType: FileType,
        document data: Data
    ) throws -> URL {
        try createSmileFile(to: jobId, name: filename(for: fileType.name), file: data)
    }

    public static func getFileByType(
        jobId: String,
        fileType: FileType,
        submitted: Bool = false
    ) throws -> URL? {
        let contents = try getDirectoryContents(jobId: jobId, submitted: submitted)
        return contents.first(where: { $0.lastPathComponent.contains(fileType.name) })
    }

    public static func getFilesByType(
        jobId: String,
        fileType: FileType,
        submitted: Bool = false
    ) throws -> [URL]? {
        let contents = try getDirectoryContents(jobId: jobId, submitted: submitted)
        return contents.filter { $0.lastPathComponent.contains(fileType.name) }
    }

    static func createInfoJsonFile(
        jobId: String,
        idInfo: IdInfo? = nil,
        consentInformation: ConsentInformation? = nil,
        documentFront: URL? = nil,
        documentBack: URL? = nil,
        selfie: URL? = nil,
        livenessImages: [URL]? = nil
    ) throws -> URL {
        var imageInfoArray = [UploadImageInfo]()
        if let selfie {
            imageInfoArray.append(UploadImageInfo(
                imageTypeId: .selfieJpgFile,
                fileName: selfie.lastPathComponent
            ))
        }
        if let livenessImages {
            let livenessImageInfos = livenessImages.map { liveness in
                UploadImageInfo(
                    imageTypeId: .livenessJpgFile,
                    fileName: liveness.lastPathComponent
                )
            }
            imageInfoArray.append(contentsOf: livenessImageInfos)
        }
        if let documentFront {
            imageInfoArray.append(UploadImageInfo(
                imageTypeId: .idCardJpgFile,
                fileName: documentFront.lastPathComponent
            ))
        }
        if let documentBack {
            imageInfoArray.append(UploadImageInfo(
                imageTypeId: .idCardRearJpgFile,
                fileName: documentBack.lastPathComponent
            ))
        }
        let data = try jsonEncoder.encode(UploadRequest(
            images: imageInfoArray,
            idInfo: idInfo,
            consentInformation: consentInformation
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

    static func saveOfflineJob(
        jobId: String,
        userId: String,
        jobType: JobType,
        enrollment: Bool,
        allowNewEnroll: Bool,
        metadata: [Metadatum],
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
                    allowNewEnroll: allowNewEnroll,
                    metadata: metadata,
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
        jobId: String,
        submitted: Bool = false
    ) throws -> [URL] {
        let baseDirectory = try submitted ? submittedJobDirectory : unsubmittedJobDirectory
        let folderPathURL = baseDirectory.appendingPathComponent(jobId)
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
        if fileManager.fileExists(atPath: submittedFileDirectory.relativePath) {
            try fileManager.removeItem(atPath: submittedFileDirectory.relativePath)
        }
        try fileManager.moveItem(at: unsubmittedFileDirectory, to: submittedFileDirectory)
    }

    /// Moves files from unsubmitted to submitted when not in Offline Mode, or if it was not a
    /// network error
    /// Returns: true if files were moved
    static func handleOfflineJobFailure(
        jobId: String,
        error: SmileIDError
    ) throws -> Bool {
        var didMove = false
        if !SmileID.allowOfflineMode && !SmileIDError.isNetworkFailure(error: error) {
            try LocalStorage.moveToSubmittedJobs(jobId: jobId)
            didMove = true
        }
        return didMove
    }

    public static func toZip(uploadRequest: UploadRequest) throws -> Data {
        var destinationFolder: String?
        // Extract directory paths from all images and check for consistency
        for imageInfo in uploadRequest.images {
            let folder = extractDirectoryPath(from: imageInfo.fileName)
            if let existingDestinationFolder = destinationFolder {
                if folder != existingDestinationFolder {
                    throw SmileIDError.fileNotFound("Job not found")
                }
            } else {
                destinationFolder = folder
            }
        }

        // Ensure a destination folder was found
        guard let finalDestinationFolder = destinationFolder else {
            throw SmileIDError.fileNotFound("Job not found")
        }

        // Create full URLs for all images
        let imageUrls = uploadRequest.images.map { imageInfo in
            URL(fileURLWithPath: finalDestinationFolder).appendingPathComponent(imageInfo.fileName)
        }

        var allUrls = imageUrls

        do {
            // Get the URL for the JSON file
            let jsonUrl = try LocalStorage.getInfoJsonFile(jobId: finalDestinationFolder)
            allUrls.append(jsonUrl)
        } catch {
            debugPrint("Warning: info.json file not found. Continuing without it.")
        }

        // Zip all files
        return try zipFiles(urls: allUrls)
    }

    public static func zipFiles(urls: [URL] = [], data: [String: Data] = [:]) throws -> Data {
        let archive = try Archive(accessMode: .create)

        // Add files from disk
        for url in urls {
            try archive.addEntry(with: url.lastPathComponent, fileURL: url)
        }

        // Add in-memory files
        for (filename, content) in data {
            try archive.addEntry(
                with: filename,
                type: .file,
                uncompressedSize: Int64(content.count)
            ) { position, size in
                return content.subdata(in: Int(position)..<Int(position) + size)
            }
        }

        return archive.data!
    }

    private static func extractDirectoryPath(from path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        // Remove the last component and add a trailing slash
        let directoryPath = url.deletingLastPathComponent().path + "/"
        return directoryPath
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
        if try fileManager.fileExists(atPath: defaultDirectory.relativePath) {
            try fileManager.removeItem(atPath: defaultDirectory.relativePath)
        }
    }

    static func deleteLivenessAndSelfieFiles(at jobIds: [String]) throws {
        func deleteMatchingFiles(in directory: URL) throws {
            let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            try contents.forEach { url in
                let filename = url.lastPathComponent
                if filename.starts(with: "si_liveness_") || filename.starts(with: "si_selfie_") {
                    try delete(at: url)
                }
            }
        }

        try jobIds.forEach { jobId in
            let unsubmittedJob = try unsubmittedJobDirectory.appendingPathComponent(jobId)
            try deleteMatchingFiles(in: unsubmittedJob)

            let submittedJob = try submittedJobDirectory.appendingPathComponent(jobId)
            try deleteMatchingFiles(in: submittedJob)
        }
    }
}

public extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
