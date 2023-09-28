import Foundation
import Zip

class LocalStorage {
    private static let defaultFolderName = "sid_jobs"
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

    static func saveImageJpg(
        livenessImages: [Data],
        previewImage: Data,
        to folder: String = "sid-\(UUID().uuidString)"
    ) throws -> SelfieCaptureResultStore {
        try createDefaultDirectory()
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var allFileUrls = [URL]()
        var livenessUrls = [URL]()
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = try livenessImages.map({ [self] imageData in
            let fileName = filename(for: "liveness")
            let url = try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            allFileUrls.append(url)
            livenessUrls.append(url)
            return UploadImageInfo(imageTypeId: .livenessJpgFile, fileName: fileName)
        })
        let fileName = filename(for: "selfie")
        let selfieUrl = try write(
            previewImage,
            to: destinationFolder.appendingPathComponent(fileName)
        )
        allFileUrls.append(selfieUrl)
        imageInfoArray.append(UploadImageInfo(imageTypeId: .selfieJpgFile, fileName: fileName))
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray))
        let jsonUrl = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        allFileUrls.append(jsonUrl)
        return SelfieCaptureResultStore(
            allFiles: allFileUrls,
            selfie: selfieUrl,
            livenessImages: livenessUrls
        )
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
        to folder: String = "sid-\(UUID().uuidString)"
    ) throws -> DocumentCaptureResultStore {
        try createDefaultDirectory()
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

    private static func createDefaultDirectory() throws {
        try createDirectory(at: defaultDirectory, overwrite: false)
    }

    private static func filename(for imageType: String) -> String {
        "\(imagePrefix)\(imageType)_\(Date().millisecondsSince1970).jpg"
    }

    static func write(_ data: Data, to url: URL) throws -> URL {
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

    static func zipFiles(at urls: [URL]) throws -> URL {
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

fileprivate extension Data {
    var asLivenessImageInfo: UploadImageInfo {
        UploadImageInfo(
            imageTypeId: .livenessJpgBase64,
            fileName: base64EncodedString()
        )
    }

    var asSelfieImageInfo: UploadImageInfo {
        UploadImageInfo(
            imageTypeId: .selfieJpgBase64,
            fileName: base64EncodedString()
        )
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
