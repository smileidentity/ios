import VideoToolbox

public extension CVPixelBuffer {
  func makeCGImage() -> CGImage? {
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(
      self,
      options:
      nil,
      imageOut: &cgImage
    )
    return cgImage
  }
}
