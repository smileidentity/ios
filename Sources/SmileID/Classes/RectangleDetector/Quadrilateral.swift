//  Created by Boris Emorine on 2/9/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//  Source: https://github.com/WeTransfer/WeScan

import Vision
import UIKit

struct Quadrilateral: Transformable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    var path: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.close()

        return path
    }

    var cgRect: CGRect {
        let minX = min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y)

        let maxX = max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x)
        let maxY = max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y)

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    var perimeter: Double {
        let perimeter = topLeft.distanceTo(point: topRight)
        + topRight.distanceTo(point: bottomRight)
        + bottomRight.distanceTo(point: bottomLeft)
        + bottomLeft.distanceTo(point: topLeft)
        return Double(perimeter)
    }

    var aspectRatio: Double {
        abs(topLeft.y - bottomLeft.y) / abs(topLeft.x - topRight.x)
    }

    init(rectangleObservation: VNRectangleObservation) {
        self.topLeft = rectangleObservation.topLeft
        self.topRight = rectangleObservation.topRight
        self.bottomLeft = rectangleObservation.bottomLeft
        self.bottomRight = rectangleObservation.bottomRight
    }

    init(cgRect: CGRect) {
        self.topLeft = cgRect.topLeft
        self.topRight = cgRect.topRight
        self.bottomLeft = cgRect.bottomLeft
        self.bottomRight = cgRect.bottomRight
    }

    init(topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

    func applying(_ transform: CGAffineTransform) -> Quadrilateral {
        let quadrilateral = Quadrilateral(
            topLeft: topLeft.applying(transform),
            topRight: topRight.applying(transform),
            bottomRight: bottomRight.applying(transform),
            bottomLeft: bottomLeft.applying(transform)
        )

        return quadrilateral
    }

    /// Converts the current to the cartesian coordinate system (where 0 on the y axis is at the bottom).
    ///
    /// - Parameters:
    ///   - height: The height of the rect containing the quadrilateral.
    /// - Returns: The same quadrilateral in the cartesian coordinate system.
    func toCartesian(withHeight height: CGFloat) -> Quadrilateral {
        let topLeft = self.topLeft.cartesian(withHeight: height)
        let topRight = self.topRight.cartesian(withHeight: height)
        let bottomRight = self.bottomRight.cartesian(withHeight: height)
        let bottomLeft = self.bottomLeft.cartesian(withHeight: height)

        return Quadrilateral(topLeft: topLeft,
                             topRight: topRight,
                             bottomRight: bottomRight,
                             bottomLeft: bottomLeft)
    }

    /// Checks whether the quadrilateral is within a given distance of another quadrilateral.
    ///
    /// - Parameters:
    ///   - distance: The distance (threshold) to use for the condition to be met.
    ///   - rectangleFeature: The other rectangle to compare this instance with.
    /// - Returns: True if the given rectangle is within the given distance of this rectangle instance.
    func isWithin(_ distance: CGFloat, ofRectangleFeature rectangleFeature: Quadrilateral) -> Bool {

        let topLeftRect = topLeft.surroundingSquare(withSize: distance)
        if !topLeftRect.contains(rectangleFeature.topLeft) {
            return false
        }

        let topRightRect = topRight.surroundingSquare(withSize: distance)
        if !topRightRect.contains(rectangleFeature.topRight) {
            return false
        }

        let bottomRightRect = bottomRight.surroundingSquare(withSize: distance)
        if !bottomRightRect.contains(rectangleFeature.bottomRight) {
            return false
        }

        let bottomLeftRect = bottomLeft.surroundingSquare(withSize: distance)
        if !bottomLeftRect.contains(rectangleFeature.bottomLeft) {
            return false
        }

        return true
    }

    /// Scales the quadrilateral based on the ratio of two given sizes, and optionally applies a rotation.
    ///
    /// - Parameters:
    ///   - fromSize: The size the quadrilateral is currently related to.
    ///   - toSize: The size to scale the quadrilateral to.
    ///   - rotationAngle: The optional rotation to apply.
    /// - Returns: The newly scaled and potentially rotated quadrilateral.
    func scale(_ fromSize: CGSize,
               _ toSize: CGSize,
               withRotationAngle rotationAngle: CGFloat = 0.0) -> Quadrilateral {
        var invertedFromSize = fromSize
        let rotated = rotationAngle != 0.0

        if rotated && rotationAngle != CGFloat.pi {
            invertedFromSize = CGSize(width: fromSize.height, height: fromSize.width)
        }

        var transformedQuad = self
        let invertedFromSizeWidth = invertedFromSize.width == 0 ? .leastNormalMagnitude : invertedFromSize.width
        let invertedFromSizeHeight = invertedFromSize.height == 0 ? .leastNormalMagnitude : invertedFromSize.height

        let scaleWidth = toSize.width / invertedFromSizeWidth
        let scaleHeight = toSize.height / invertedFromSizeHeight
        let scaledTransform = CGAffineTransform(scaleX: scaleWidth, y: scaleHeight)
        transformedQuad = transformedQuad.applying(scaledTransform)

        if rotated {
            let rotationTransform = CGAffineTransform(rotationAngle: rotationAngle)

            let fromImageBounds = CGRect(origin: .zero, size: fromSize)
                .applying(scaledTransform)
                .applying(rotationTransform)

            let toImageBounds = CGRect(origin: .zero, size: toSize)
            let translationTransform = CGAffineTransform.translateTransform(
                fromCenterOfRect: fromImageBounds,
                toCenterOfRect: toImageBounds
            )

            transformedQuad = transformedQuad.applyTransforms([rotationTransform, translationTransform])
        }

        return transformedQuad
    }

    /// Reorganizes the current quadrilateral, making sure that the points are at their appropriate positions.
    /// For example, it ensures that the top left point is actually the top and left point point of the quadrilateral.
    mutating func reorganize() {
        let points = [topLeft, topRight, bottomRight, bottomLeft]
        let ySortedPoints = sortPointsByYValue(points)

        guard ySortedPoints.count == 4 else {
            return
        }

        let topMostPoints = Array(ySortedPoints[0..<2])
        let bottomMostPoints = Array(ySortedPoints[2..<4])
        let xSortedTopMostPoints = sortPointsByXValue(topMostPoints)
        let xSortedBottomMostPoints = sortPointsByXValue(bottomMostPoints)

        guard xSortedTopMostPoints.count > 1,
              xSortedBottomMostPoints.count > 1 else {
            return
        }

        topLeft = xSortedTopMostPoints[0]
        topRight = xSortedTopMostPoints[1]
        bottomRight = xSortedBottomMostPoints[1]
        bottomLeft = xSortedBottomMostPoints[0]
    }

    /// Sorts the given `CGPoints` based on their y value.
    /// - Parameters:
    ///   - points: The points to sort.
    /// - Returns: The points sorted based on their y value.
    private func sortPointsByYValue(_ points: [CGPoint]) -> [CGPoint] {
        return points.sorted { point1, point2 -> Bool in
            point1.y < point2.y
        }
    }

    /// Sorts the given `CGPoints` based on their x value.
    /// - Parameters:
    ///   - points: The points to sort.
    /// - Returns: The points sorted based on their x value.
    private func sortPointsByXValue(_ points: [CGPoint]) -> [CGPoint] {
        return points.sorted { point1, point2 -> Bool in
            point1.x < point2.x
        }
    }

}

extension Array where Element == Quadrilateral {

    /// Finds the largest rectangle within an array of `Quadrilateral` objects.
    func largest() -> Quadrilateral? {
        let biggestRectangle = self.max(by: { rect1, rect2 -> Bool in
            return rect1.perimeter < rect2.perimeter
        })
        return biggestRectangle
    }

}

extension CGPoint {

    /// Returns a rectangle of a given size surrounding the point.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle that should surround the points.
    /// - Returns: A `CGRect` instance that surrounds this instance of `CGPoint`.
    func surroundingSquare(withSize size: CGFloat) -> CGRect {
        return CGRect(x: x - size / 2.0, y: y - size / 2.0, width: size, height: size)
    }

    /// Checks wether this point is within a given distance of another point.
    ///
    /// - Parameters:
    ///   - delta: The minimum distance to meet for this distance to return true.
    ///   - point: The second point to compare this instance with.
    /// - Returns: True if the given `CGPoint` is within the given distance of this instance of `CGPoint`.
    func isWithin(delta: CGFloat, ofPoint point: CGPoint) -> Bool {
        return (abs(x - point.x) <= delta) && (abs(y - point.y) <= delta)
    }

    /// Returns the same `CGPoint` in the cartesian coordinate system.
    ///
    /// - Parameters:
    ///   - height: The height of the bounds this points belong to, in the current coordinate system.
    /// - Returns: The same point in the cartesian coordinate system.
    func cartesian(withHeight height: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: height - y)
    }

    /// Returns the distance between two points
    func distanceTo(point: CGPoint) -> CGFloat {
        return hypot((self.x - point.x), (self.y - point.y))
    }
}

extension CGRect {
    var topLeft: CGPoint {
        return CGPoint(x: self.minX, y: self.minY)
    }

    var topRight: CGPoint {
        return CGPoint(x: self.maxX, y: self.minY)
    }

    var bottomRight: CGPoint {
        return CGPoint(x: self.maxX, y: self.maxY)
    }

    var bottomLeft: CGPoint {
        return CGPoint(x: self.minX, y: self.maxY)
    }
}
