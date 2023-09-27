//  Created by Boris Emorine on 2/9/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//  Source: https://github.com/WeTransfer/WeScan

import Foundation
import Vision

class RectangleDetector {
    private static func completeImageRequest(
        for request: VNImageRequestHandler,
        width: CGFloat,
        height: CGFloat,
        aspectRatio: Double?,
        completion: @escaping ((Quadrilateral?) -> Void)
    ) {
        // Create the rectangle request, and, if found, return the largest rectangle (else return nothing).
        let rectangleDetectionRequest: VNDetectRectanglesRequest = {
            let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: { request, error in
                guard error == nil, let results = request.results as? [VNRectangleObservation], !results.isEmpty else {
                    completion(nil)
                    return
                }

                let quads: [Quadrilateral] = results.map(Quadrilateral.init)

                guard let largest = quads.largest() else {
                    completion(nil)
                    return
                }

                let transform = CGAffineTransform.identity
                    .scaledBy(x: width, y: height)

                completion(largest.applying(transform))
            })

            rectDetectRequest.minimumConfidence = 0.8

            return rectDetectRequest
        }()

        // Send the requests to the request handler.
        do {
            try request.perform([rectangleDetectionRequest])
        } catch {
            completion(nil)
            return
        }

    }

    /// Detects rectangles from the given CVPixelBuffer/CVImageBuffer
    ///
    /// - Parameters:
    ///   - pixelBuffer: The pixelBuffer to detect rectangles on.
    ///   - aspectRatio: The aspect ratio of rectangles to detect
    ///   - completion: The biggest rectangle on the CVPixelBuffer
    static func rectangle(forPixelBuffer pixelBuffer: CVPixelBuffer,
                          aspectRatio: Double?,
                          completion: @escaping ((Quadrilateral?) -> Void)) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        RectangleDetector.completeImageRequest(
            for: imageRequestHandler,
            width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
            height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)),
            aspectRatio: aspectRatio,
            completion: completion)
    }
}

protocol RectangleDetectionDelegate: NSObjectProtocol {
    /// Called when a quadrilateral has been detected.
    /// - Parameters:
    ///   - quad: The detected quadrilateral in the coordinates of the image.
    ///   - imageSize: The size of the image the quadrilateral has been detected on.
    func didDetectQuad(quad: Quadrilateral?, _ imageSize: CGSize, completion: ((Quadrilateral) -> Void)? )
}

/// Data structure representing the result of the detection of a quadrilateral.
struct RectangleDetectorResult {

    /// The detected quadrilateral.
    let rectangle: Quadrilateral

    /// The size of the image the quadrilateral was detected on.
    let imageSize: CGSize

}
