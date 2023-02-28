// swiftlint:disable force_try
import Foundation
import Zip

class LocalStorage {
    private static let defaultFolderName = "sid_jobs"
    private static let livenessImagePrefix = "LIV_"
    private static let fileManager = FileManager.default
    private static let previewImageName = "PreviewImage.jpg"
    private static let jsonEncoder = JSONEncoder()

    static var defaultDirectory: URL {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory,
                                                             in: .userDomainMask,
                                                             appropriateFor: nil,
                                                             create: true)
        return documentDirectory.appendingPathComponent(defaultFolderName)
    }

    static func saveImageJpg(livenessImages: [Data], previewImage: Data, to folder: String) throws -> URL {
        try createDefaultDirectory()
        let destinationFolder = defaultDirectory.appendingPathComponent(folder)
        try createDirectory(at: destinationFolder, overwrite: false)
        var imageInfoArray = try livenessImages.enumerated().map({ [self] index, imageData in
            let fileName = "\(livenessImagePrefix)\(index).jpg"
            try write(imageData, to: destinationFolder.appendingPathComponent(fileName))
            return imageData.asLivenessImageInfo
        })
        try write(previewImage, to: destinationFolder.appendingPathComponent(previewImageName))
        imageInfoArray.append(previewImage.asSelfieImageInfo)
        let jsonData = try jsonEncoder.encode(UploadRequest(images: imageInfoArray))
        try write(jsonData, to: destinationFolder.appendingPathComponent("info.json"))
        return destinationFolder
    }

    private static func createDefaultDirectory() throws {
        try createDirectory(at: defaultDirectory, overwrite: false)
    }

    static func write(_ data: Data, to url: URL) throws {
        if !fileManager.fileExists(atPath: url.relativePath) {
            try data.write(to: url)
        } else {
            try fileManager.removeItem(atPath: url.relativePath)
            try data.write(to: url)
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

    static func zipFolder(folderUrl: URL) throws -> URL {
        return try Zip.quickZipFiles([folderUrl], fileName: "archive")
    }

    static func delete(at url: URL) throws {
        if fileManager.fileExists(atPath: url.relativePath) {
            try fileManager.removeItem(atPath: url.relativePath)
        }
    }

    static func deleteAll() throws {
        if fileManager.fileExists(atPath: defaultDirectory.relativePath) {
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
