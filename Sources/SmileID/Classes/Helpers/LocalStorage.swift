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
            let documentDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: nil,
                                                                create: true)
            return documentDirectory.appendingPathComponent(defaultFolderName)
        }
    }

    static func saveImageJpg(livenessImages: [Data],
                             previewImage: Data,
                             to folder: String = "sid-\(UUID().uuidString)"
    ) throws -> [URL] {
        try createDefaultDirectory()
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var urls = [URL]()
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = try livenessImages.map({ [self] imageData in
            let fileName = filename(for: "liveness")
            let url =  try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            urls.append(url)
            return UploadImageInfo(imageTypeId: .livenessJpgFile, fileName: fileName)
        })
        let fileName = filename(for: "selfie")
        let previewUrl = try write(previewImage, to: destinationFolder.appendingPathComponent(fileName))
        urls.append(previewUrl)
        imageInfoArray.append(UploadImageInfo(imageTypeId: .selfieJpgFile, fileName: fileName))
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray))
        let jsonUrl = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        urls.append(jsonUrl)
        return urls
    }

    /// Saves front and back images of documents to disk, generates an `info.json`
    /// and returns the url of all the files that have been saved
    /// - Parameters:
    ///   - front: Jpg data representation id image fron
    ///   - back: Jpg data for the back of tha id image
    ///   - folder: The name of the folder the files should be saved
    /// - Returns: An array of urls of all the files that have been saved to disk
    static func saveDocumentImages(front: Data,
                                   back: Data?,
                                   livenessImages: [Data],
                                   selfie: Data,
                                   document: Document,
                                   to folder: String = "sid-\(UUID().uuidString)") throws -> [URL] {
        try createDefaultDirectory()
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var urls = [URL]()
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = [UploadImageInfo]()
        let filename = filename(for: "idFront")
        let url =  try write(front, to: destinationFolder.appendingPathComponent(filename))
        urls.append(url)
        imageInfoArray.append(UploadImageInfo(imageTypeId: .idCardJpgFile, fileName: filename))

        if let back = back {
            let filename = self.filename(for: "idBack")
            let url =  try write(back, to: destinationFolder.appendingPathComponent(filename))
            urls.append(url)
            imageInfoArray.append(UploadImageInfo(imageTypeId: .idCardRearJpgFile, fileName: filename))
        }
        let livenessInfoArray = try livenessImages.map({ [self] imageData in
            let fileName = self.filename(for: "liveness")
            let url =  try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            urls.append(url)
            return UploadImageInfo(imageTypeId: .livenessJpgFile, fileName: fileName)
        })
        imageInfoArray.append(contentsOf: livenessInfoArray)
        let selfieFileName = self.filename(for: "selfie")
        let selfieUrl = try write(selfie, to: destinationFolder.appendingPathComponent(selfieFileName))
        urls.append(selfieUrl)
        imageInfoArray.append(UploadImageInfo(imageTypeId: .selfieJpgFile, fileName: selfieFileName))
        let idInfo = IdInfo(country: document.countryCode, idType: document.documentType ?? "")
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray, idInfo: idInfo))
        let jsonUrl = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        urls.append(jsonUrl)
        return urls
    }

    private static func createDefaultDirectory() throws {
        try createDirectory(at: defaultDirectory, overwrite: false)
    }

    private static func filename(for imageType: String) -> String {
        return "\(imagePrefix)\(imageType)_\(Date().millisecondsSince1970).jpg"
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
        return try Zip.quickZipFiles(urls, fileName: "upload")
    }

    static func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.relativePath) {
            try fileManager.removeItem(atPath: url.relativePath)
        }
    }

    static func delete(at urls: [URL]) throws {
        for url in urls {
            if fileManager.fileExists(atPath: url.relativePath) {
                try fileManager.removeItem(atPath: url.relativePath)
            }
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
        return UploadImageInfo(imageTypeId: .livenessJpgBase64,
                               fileName: self.base64EncodedString()
        )
    }

    var asSelfieImageInfo: UploadImageInfo {
        return UploadImageInfo(imageTypeId: .selfieJpgBase64,
                               fileName: self.base64EncodedString())
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
