import SwiftUI

extension Image {
    init(packageResource name: String, ofType type: String) {
#if canImport(UIKit)
        guard let path = SmileIDResourcesHelper.bundle.path(forResource: name, ofType: type),
              let image = UIImage(contentsOfFile: path) else {
            self.init(name)
            return
        }
        self.init(uiImage: image)
#elseif canImport(AppKit)
        guard let path = mileIDResourcesHelper.bundle.path(forResource: name, ofType: type),
              let image = NSImage(contentsOfFile: path) else {
            self.init(name)
            return
        }
        self.init(nsImage: image)
#else
        self.init(name)
#endif
    }
}
