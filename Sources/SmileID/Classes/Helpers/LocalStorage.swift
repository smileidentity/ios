import Foundation
import Zip

public class LocalStorage {
    private static let defaultFolderName = "SmileID"
    private static let pendingFolderName = "unsubmitted"
    private static let completedFolderName = "submitted"
    private static let imagePrefix = "si_"
    private static let fileManager = FileManager.default
    private static let previewImageName = "PreviewImage.jpg"
    private static let jsonEncoder = JSONEncoder()

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

    static var unsubmittedDirectory: URL {
        get throws {
            try defaultDirectory.appendingPathComponent(pendingFolderName)
        }
    }

    static var submittedDirectory: URL {
        get throws {
            try defaultDirectory.appendingPathComponent(completedFolderName)
        }
    }

    private static func createSmileFile(
        to folder: String,
        name: String,
        file data: Data
    ) throws -> URL {
        try createDirectory(at: defaultDirectory, overwrite: false)
        try createDirectory(at: unsubmittedDirectory, overwrite: false)
        let destinationFolder = try unsubmittedDirectory.appendingPathComponent(folder)
        return try write(data, to: destinationFolder.appendingPathComponent(name))
    }

    private static func filename(for name: String) -> String {
        "\(imagePrefix)\(name)_\(Date().millisecondsSince1970).jpg"
    }

    static func createSelfieFile(
        jobId: String,
        selfieFile data: Data
    ) throws -> URL {
        return try createSmileFile(to: jobId, name: filename(for: "selfie"), file: data)
    }

    static func createLivenessFile(
        jobId: String,
        livenessFile data: Data
    ) throws -> URL {
        return try createSmileFile(to: jobId, name: filename(for: "liveness"), file: data)
    }

    static func createDocumentFile(
        jobId: String,
        document data: Data
    ) throws -> URL {
        return try createSmileFile(to: jobId, name: filename(for: "document"), file: data)
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

    private static func createPreUploadFile(
        jobId: String,
        partnerParams: PartnerParams,
        allowNewEnroll: Bool
    ) throws -> URL {
        let data = try jsonEncoder.encode(PrepUploadRequest(
            partnerParams: partnerParams,
            allowNewEnroll: String(allowNewEnroll) // TODO - Fix when Michael changes
        ))
        return try createSmileFile(to: jobId, name: "preupload.json", file: data)
    }

    private static func createAuthenticationRequestFile(
        jobId: String,
        userId: String,
        jobType: JobType,
        enrollment: Bool
    ) throws -> URL {
        let data = try jsonEncoder.encode(AuthenticationRequest(
            jobType: jobType,
            enrollment: enrollment,
            jobId: jobId,
            userId: userId
        ))
        return try createSmileFile(to: jobId, name: "authenticationrequest.json", file: data)
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
            _ = try createPreUploadFile(
                jobId: jobId,
                partnerParams: PartnerParams(
                    jobId: jobId,
                    userId: userId,
                    jobType: jobType,
                    extras: partnerParams
                ),
                allowNewEnroll: allowNewEnroll
            )
            _ = try createAuthenticationRequestFile(
                jobId: jobId,
                userId: userId,
                jobType: jobType,
                enrollment: enrollment
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

    private static func createDirectory(at url: URL, overwrite: Bool = true) throws {
        if !fileManager.fileExists(atPath: url.relativePath) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        } else {
            if overwrite {
                try delete(at: url)
                try createDirectory(at: url)
            }
        }
    }

    // todo - rework this as we change zip library
    public static func toZip(
        uploadRequest: UploadRequest,
        to folder: String = "sid-\(UUID().uuidString)"
    ) throws -> URL {
        try createDirectory(at: defaultDirectory, overwrite: false)
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

    static func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.relativePath) {
            try fileManager.removeItem(atPath: url.relativePath)
        }
    }

    static func delete(at urls: [URL]) throws {
        for url in urls where fileManager.fileExists(atPath: url.relativePath) {
            try fileManager.removeItem(atPath: url.relativePath)
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
