import Foundation
import Zip

public class LocalStorage {
    private static let defaultFolderName = "sid_jobs"
    private static let pendingFolderName = "pending"
    private static let completedFolderName = "completed"
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

    static var pendingDirectory: URL {
        get throws {
            return try defaultDirectory.appendingPathComponent(pendingFolderName)
        }
    }

    static var completedDirectory: URL {
        get throws {
            return try defaultDirectory.appendingPathComponent(completedFolderName)
        }
    }

    static func saveImage(
        image: Data,
        to folder: String = "sid-\(UUID().uuidString)",
        name: String
    ) throws -> URL {
        try createSmileDirectory(name: defaultDirectory)
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        try createDirectory(at: destinationFolder, overwrite: false)
        let fileName = filename(for: name)
        return try write(image, to: destinationFolder.appendingPathComponent(fileName))
    }

    static func saveSelfieImages(
        selfieImage: Data,
        livenessImages: [Data],
        jobId folder: String
    ) throws -> SelfieCaptureResultStore {
        try createSmileDirectory(name: defaultDirectory)
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var livenessUrls = [URL]()
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = try livenessImages.map { [self] imageData in
            let fileName = filename(for: "liveness")
            let url = try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            livenessUrls.append(url)
            return UploadImageInfo(imageTypeId: .livenessJpgFile, fileName: fileName)
        }
        let fileName = filename(for: "selfie")
        let selfieUrl = try write(
            selfieImage,
            to: destinationFolder.appendingPathComponent(fileName)
        )
        imageInfoArray.append(UploadImageInfo(imageTypeId: .selfieJpgFile, fileName: fileName))
        return SelfieCaptureResultStore(
            selfie: selfieUrl,
            livenessImages: livenessUrls
        )
    }

    static func createInfoJson(
        selfie: URL,
        livenessImages: [URL],
        idInfo: IdInfo? = nil,
        jobId folder: String
    ) throws -> URL {
        try createSmileDirectory(name: defaultDirectory)
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var imageInfoArray: [UploadImageInfo] = []
        imageInfoArray.append(
            UploadImageInfo(imageTypeId: .selfieJpgFile, fileName: selfie.lastPathComponent)
        )
        for livenessImage in livenessImages {
            imageInfoArray.append(
                UploadImageInfo(
                    imageTypeId: .livenessJpgFile,
                    fileName: livenessImage.lastPathComponent
                )
            )
        }
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray, idInfo: idInfo))
        let url = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        return url
    }

    /// Saves front and back images of documents to disk, generates an `info.json`
    /// and returns the url of all the files that have been saved
    /// - Parameters:
    ///   - front: JPEG data representation ID image front
    ///   - back: JPEG data for the back of the ID image
    ///   - livenessImages: The selfie capture liveness images
    ///   - selfie: The selfie capture
    ///   - countryCode: The document country code
    ///   - documentType: The optional document type
    ///   - folder: The name of the folder the files should be saved
    /// - Returns: A document result store which encapsulates the urls of the saved images
    static func saveDocumentImages(
        front: Data,
        back: Data?,
        selfie: Data,
        livenessImages: [Data]?,
        countryCode: String,
        documentType: String?,
        jobId folder: String
    ) throws -> DocumentCaptureResultStore {
        try createSmileDirectory(name: defaultDirectory)
        try createSmileDirectory(name: pendingDirectory)
        try createSmileDirectory(name: completedDirectory)
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var allFiles = [URL]()
        var livenessImagesUrl = [URL]()
        var documentBack: URL?
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = [UploadImageInfo]()
        let filename = filename(for: "idFront")
        let documentFront = try write(front, to: destinationFolder.appendingPathComponent(filename))
        allFiles.append(documentFront)
        imageInfoArray.append(UploadImageInfo(imageTypeId: .idCardJpgFile, fileName: filename))

        if let back = back {
            let filename = self.filename(for: "idBack")
            let url = try write(back, to: destinationFolder.appendingPathComponent(filename))
            documentBack = url
            allFiles.append(url)
            imageInfoArray.append(
                UploadImageInfo(imageTypeId: .idCardRearJpgFile, fileName: filename)
            )
        }
        let livenessInfoArray = try livenessImages?.map { [self] imageData in
            let fileName = self.filename(for: "liveness")
            let url = try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            allFiles.append(url)
            livenessImagesUrl.append(url)
            return UploadImageInfo(imageTypeId: .livenessJpgFile, fileName: fileName)
        }
        if let livenessInfoArray = livenessInfoArray {
            imageInfoArray.append(contentsOf: livenessInfoArray)
        }
        let selfieFileName = self.filename(for: "selfie")
        let selfieUrl = try write(
            selfie,
            to: destinationFolder.appendingPathComponent(selfieFileName)
        )
        allFiles.append(selfieUrl)
        imageInfoArray.append(
            UploadImageInfo(imageTypeId: .selfieJpgFile, fileName: selfieFileName)
        )
        let idInfo = IdInfo(country: countryCode, idType: documentType)
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray, idInfo: idInfo))
        let jsonUrl = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        allFiles.append(jsonUrl)
        return DocumentCaptureResultStore(
            allFiles: allFiles,
            documentFront: documentFront,
            documentBack: documentBack,
            selfie: selfieUrl,
            livenessImages: livenessImagesUrl
        )
    }

    static func createSmileDirectory(name: URL) throws {
        try createDirectory(at: name, overwrite: false)
    }

    private static func filename(for imageType: String) -> String {
        "\(imagePrefix)\(imageType)_\(Date().millisecondsSince1970).jpg"
    }

    static func write(_ data: Data, to url: URL) throws -> URL {
        let directoryURL = url.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        if !fileManager.fileExists(atPath: url.relativePath) {
            try data.write(to: url)
            return url
        } else {
            try fileManager.removeItem(atPath: url.relativePath)
            try data.write(to: url)
            return url
        }
    }

    static func createDirectory(at url: URL, overwrite: Bool = true) throws {
        if !fileManager.fileExists(atPath: url.relativePath) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        } else {
            if overwrite {
                try delete(at: url)
                try createDirectory(at: url)
            }
        }
    }

    public static func toZip(
        uploadRequest: UploadRequest,
        jobId folder: String
    ) throws -> URL {
        try createSmileDirectory(name: defaultDirectory)
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
