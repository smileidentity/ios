import SwiftUI

extension Image {
    init(packageResource name: String, ofType type: String) {
        #if canImport(UIKit)
        guard let path = SmileIDResourcesHelper.bundle.path(forResource: name, ofType: type),
              let image = UIImage(contentsOfFile: path)
        else {
            self.init(name)
            return
        }
        self.init(uiImage: image)
        #elseif canImport(AppKit)
        guard let path = SmileIDResourcesHelper.bundle.path(forResource: name, ofType: type),
              let image = NSImage(contentsOfFile: path)
        else {
            self.init(name)
            return
        }
        self.init(nsImage: image)
        #else
        self.init(name)
        #endif
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            assertionFailure("Unknown orientation, falling to default")
            self = .right
        }
    }
}

extension UIImage {
    /// Creates a UIImage from the specified CIImage.
    static func from(ciImage: CIImage) -> UIImage {
        if let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return UIImage(ciImage: ciImage, scale: 1.0, orientation: .up)
        }
    }
}
