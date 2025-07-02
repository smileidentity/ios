import CoreGraphics
import CoreImage
import VideoToolbox

public extension CGImage {
  /**
     Creates a new CGImage from a CVPixelBuffer.

     - Note: Not all CVPixelBuffer pixel formats support conversion into a
             CGImage-compatible pixel format.
   */
  static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
    return cgImage
  }
}
