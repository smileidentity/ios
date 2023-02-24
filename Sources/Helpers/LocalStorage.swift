import Foundation
import Zip

class LocalStorage {
    static let defaultFolderName = "sid_jobs"
    static let livenessImagePrefix = "LIV_"
    static let fileManager = FileManager.default

    static var defaultDirectory: URL {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documentDirectory.appendingPathComponent(defaultFolderName)
    }

    static func saveImageJpg(livenessImages: [Data], previewImage: Data, to folder: String) throws -> URL {
        let destinationFolder = defaultDirectory.appendingPathComponent(folder)
        for (index, livenessImage) in livenessImages.enumerated() {
            let fileName = "\(livenessImagePrefix)\(index).jpg"
            let fileURL = destinationFolder.appendingPathComponent(fileName)
            try livenessImage.write(to: fileURL)
        }
        let previewImageName = "PreviewImage.jpg"
        let previewImageURL = destinationFolder.appendingPathComponent(previewImageName)
        try previewImage.write(to: previewImageURL)
        return destinationFolder
    }

    static func zipFolder(folderUrl: URL) throws -> URL {
        return try Zip.quickZipFiles([folderUrl], fileName: "archive")
    }

    static func deleteFolder(folderURL: URL) {
        if fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.removeItem(atPath: folderURL.path)
        }
    }

    static func deleteData() {
        if fileManager.fileExists(atPath: defaultDirectory.path) {
            try? fileManager.removeItem(atPath: defaultDirectory.path)
        }
    }
}
