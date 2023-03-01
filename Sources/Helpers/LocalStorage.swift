import Foundation
import Zip

class LocalStorage {
    private static let defaultFolderName = "sid_jobs"
    private static let livenessImagePrefix = "LIV_"
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

    static func saveImageJpg(livenessImages: [Data], previewImage: Data, to folder: String) throws -> [URL] {
        try createDefaultDirectory()
        let destinationFolder = try defaultDirectory.appendingPathComponent(folder)
        var urls = [URL]()
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = try livenessImages.enumerated().map({ [self] index, imageData in
            let fileName = "\(livenessImagePrefix)\(index).jpg"
            let url =  try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            urls.append(url)
            return imageData.asLivenessImageInfo
        })
        let previewUrl = try write(previewImage, to: destinationFolder.appendingPathComponent(previewImageName))
        urls.append(previewUrl)
        imageInfoArray.append(previewImage.asSelfieImageInfo)
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray))
        let jsonUrl = try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        urls.append(jsonUrl)
        return urls
    }

    private static func createDefaultDirectory() throws {
        try createDirectory(at: defaultDirectory, overwrite: false)
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

    static func deleteAll() throws {
        if fileManager.fileExists(atPath: try defaultDirectory.relativePath) {
            try fileManager.removeItem(atPath: defaultDirectory.relativePath)
        }
    }
}

fileprivate extension Data {
    var asLivenessImageInfo: UploadImageInfo {
        return UploadImageInfo(imageTypeId: .livenessPngOrJpgBase64,
                               image: self.base64EncodedString()
        )
    }

    var asSelfieImageInfo: UploadImageInfo {
        return UploadImageInfo(imageTypeId: .selfiePngOrJpgBase64,
                               image: self.base64EncodedString())
    }
}
