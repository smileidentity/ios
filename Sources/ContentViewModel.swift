import CoreImage
import Combine
import VideoToolbox

class ContentViewModel: ObservableObject {
    @Published var frame: CGImage?
    private let frameManager = FrameManager.shared
    private var subscribers = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
    }

    func setupSubscriptions() {
        frameManager.$sampleBuffer
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                return CGImage.create(from: buffer)
            }
            .assign(to: \.frame, on: self)
            .store(in: &subscribers)
    }
}

extension CGImage {
  static func create(from cvPixelBuffer: CVPixelBuffer?) -> CGImage? {
    guard let pixelBuffer = cvPixelBuffer else {
      return nil
    }

    var image: CGImage?
    VTCreateCGImageFromCVPixelBuffer(
      pixelBuffer,
      options: nil,
      imageOut: &image)
    return image
  }
}
