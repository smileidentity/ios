import Vision

struct Quadrilateral {
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

    var perimeter: Double {
        let perimeter = topLeft.distanceTo(point: topRight)
        + topRight.distanceTo(point: bottomRight)
        + bottomRight.distanceTo(point: bottomLeft)
        + bottomLeft.distanceTo(point: topLeft)
        return Double(perimeter)
    }

    init(rectangleObservation: VNRectangleObservation) {
        self.topLeft = rectangleObservation.topLeft
        self.topRight = rectangleObservation.topRight
        self.bottomLeft = rectangleObservation.bottomLeft
        self.bottomRight = rectangleObservation.bottomRight
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
    func distanceTo(point: CGPoint) -> CGFloat {
        return hypot((self.x - point.x), (self.y - point.y))
    }
}
