import CoreImage
import Combine
import VideoToolbox

class ContentViewModel: ObservableObject {
    @Published var frame: CGImage?
    private var cameraManager: CameraManageable
    private var subscribers = Set<AnyCancellable>()

    init(cameraManager: CameraManageable) {
        self.cameraManager = cameraManager
        setupSubscriptions()
    }

    func setupSubscriptions() {
        cameraManager.sampleBufferPublisher
            .receive(on: RunLoop.main)
            .compactMap { CGImage.create(from: $0) }
            .assign(to: \.frame, on: self)
            .store(in: &subscribers)
    }
}

extension CGImage {
    static func create(from cvPixelBuffer: CVPixelBuffer?) -> CGImage? {
        guard let pixelBuffer = cvPixelBuffer else { return nil }
        var image: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
        return image
    }
}
