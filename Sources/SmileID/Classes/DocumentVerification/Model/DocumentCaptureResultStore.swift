import Foundation

struct DocumentCaptureResultStore {
    var allFiles: [URL]
    var documentFront: URL
    var documentBack: URL?
    var selfie: URL
    var livenessImages: [URL]
}
