// swiftlint:disable force_try
import Foundation
import Zip

class LocalStorage {
    static let defaultFolderName = "sid_jobs"
    static let livenessImagePrefix = "LIV_"
    static let fileManager = FileManager.default
    static let previewImageName = "PreviewImage.jpg"
    static let jsonEncoder = JSONEncoder()

    static var defaultDirectory: URL {
        let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documentDirectory.appendingPathComponent(defaultFolderName)
    }

    static func saveImageJpg(livenessImages: [Data], previewImage: Data, to folder: String) throws -> URL {
        let destinationFolder = defaultDirectory.appendingPathComponent(folder)
        var imageInfoArray = [UploadImageInfo]()
        for (index, livenessImage) in livenessImages.enumerated() {
            let fileName = "\(livenessImagePrefix)\(index).jpg"
            let fileUrl = destinationFolder.appendingPathComponent(fileName)
            let encodedImage = livenessImage.base64EncodedString()
            let imageInfo = UploadImageInfo(imageTypeId: .livenessPngOrJpgBase64, image: encodedImage)
            imageInfoArray.append(imageInfo)
            try livenessImage.write(to: fileUrl)
        }
        let encodedSelfie = previewImage.base64EncodedString()
        let selfieInfo = UploadImageInfo(imageTypeId: .selfiePngOrJpgBase64, image: encodedSelfie)
        imageInfoArray.append(selfieInfo)
        let infoJson = UploadRequest(images: imageInfoArray)
        let infoJsonUrl = destinationFolder.appendingPathComponent("info.json")
        let jsonData = try jsonEncoder.encode(infoJson)
        try jsonData.write(to: infoJsonUrl)
        let previewImageUrl = destinationFolder.appendingPathComponent(previewImageName)
        try previewImage.write(to: previewImageUrl)
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
