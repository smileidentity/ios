import UIKit
import SwiftUI
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var sceneView: ARSCNView!
    private var detectedFaces = 0
    weak var model: SelfieCaptureViewModel?
    private var faceNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        configuration.worldAlignment = .gravity
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sceneView != nil {
            sceneView.session.pause()
        }
    }

    func pauseSession() {
        if sceneView != nil {
            sceneView.session.pause()
        }
    }

    func resumeSession() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if sceneView != nil {
            sceneView.session.run(configuration)
        }
    }

    // ARSCNViewDelegate methods

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.transparency = 0.0
        faceNode = node
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            model?.perform(action: .noFaceDetected)
            return
        }
        updateFeatures(for: faceAnchor)
        let projectedPoints = faceAnchor.verticesAndProjection(to: sceneView)
        let boundingBox = faceBoundingBox(for: projectedPoints)
        let angles = getEulerAngles(from: faceAnchor)
        let faceObservationModel = FaceGeometryModel(boundingBox: boundingBox,
                                                     roll: angles.roll as NSNumber,
                                                     yaw: angles.yaw as NSNumber)
        model?.perform(action: .faceObservationDetected(faceObservationModel))
    }

    func getEulerAngles(from faceAnchor: ARFaceAnchor) -> (roll: Float, pitch: Float, yaw: Float) {
        // Extract the 4x4 transform matrix from the face anchor.
        let transformMatrix = faceAnchor.transform
        return (
            transformMatrix.eulerAngles.roll,
            transformMatrix.eulerAngles.pitch,
            transformMatrix.eulerAngles.yaw
        )
    }

    private func faceBoundingBox(
        for projectedPoints: [ARFaceAnchor.VerticesAndProjection]
    ) -> CGRect {
        let allXs = projectedPoints.map { $0.projected.x }
        let allYs = projectedPoints.map { $0.projected.y }

        let minX = allXs.min() ?? 0
        let maxX = allXs.max() ?? 0
        let minY = allYs.min() ?? 0
        let maxY = allYs.max() ?? 0
        let boundingBox = CGRect(x: minX, y: minY, width: (maxX - minX), height: (maxY - minY))
        return boundingBox
    }

    deinit {
        if sceneView != nil {
            sceneView.session.pause()
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        if let faceAnchor = anchor as? ARFaceAnchor {

            detectedFaces += 1

            if detectedFaces > 1 {
                model?.perform(action: .multipleFacesDetected)
            }
            updateFeatures(for: faceAnchor)
            let projectedPoints = faceAnchor.verticesAndProjection(to: sceneView)
            let boundingBox = faceBoundingBox(for: projectedPoints)
            let angles = getEulerAngles(from: faceAnchor)
            let faceObservationModel = FaceGeometryModel(
                boundingBox: boundingBox,
                roll: angles.roll as NSNumber,
                yaw: angles.yaw as NSNumber
            )
            model?.perform(action: .faceObservationDetected(faceObservationModel))
        } else {
            model?.perform(action: .noFaceDetected)
            return
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARFaceAnchor {
            detectedFaces -= 1
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: "UpdateARFrame"),
            object: nil,
            userInfo: ["frame": frame]
        )
    }

    private func updateFeatures(for faceAnchor: ARFaceAnchor) {
        if let faceGeometry = faceNode?.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
        }
        let smileLeft = faceAnchor.blendShapes[.mouthSmileLeft]
        let smileRight = faceAnchor.blendShapes[.mouthSmileRight]

        if let smileL = smileLeft,
           let smileR = smileRight,
           smileL.floatValue > 0.5 && smileR.floatValue > 0.5 {
            model?.perform(action: .smileAction)
        } else {
            model?.perform(action: .noSmile)
        }
    }
}

struct ARView: UIViewControllerRepresentable {
    let preview: ARViewController
    typealias UIViewControllerType = ARViewController

    init() {
        preview = ARViewController()
    }

    func makeUIViewController(context: Context) -> ARViewController {
        preview
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

extension ARFaceAnchor {
    // struct to store the 3d vertex and the 2d projection point
    struct VerticesAndProjection {
        var vertex: SIMD3<Float>
        var projected: CGPoint
    }

    // return a struct with vertices and projection
    func verticesAndProjection(to view: ARSCNView) -> [VerticesAndProjection] {

        let points = geometry.vertices.compactMap({ (vertex) -> VerticesAndProjection? in

            let col = SIMD4<Float>(SCNVector4())
            let pos = SIMD4<Float>(SCNVector4(vertex.x, vertex.y, vertex.z, 1))

            let pworld = transform * simd_float4x4(col, col, col, pos)

            let vect = view.projectPoint(
                SCNVector3(pworld.position.x, pworld.position.y, pworld.position.z)
            )

            let point = CGPoint(x: CGFloat(vect.x), y: CGFloat(vect.y))
            return VerticesAndProjection(vertex: vertex, projected: point)
        })

        return points
    }
}

extension matrix_float4x4 {
    var position: SCNVector3 {
        SCNVector3(self[3][0], self[3][1], self[3][2])
    }

    // Retrieve euler angles from a quaternion matrix
    var eulerAngles: (yaw: Float32, pitch: Float32, roll: Float32) {
        // Get quaternions
        let qw = sqrt(1 + columns.0.x + columns.1.y + columns.2.z) / 2.0
        let qx = (columns.2.y - columns.1.z) / (qw * 4.0)
        let qy = (columns.0.z - columns.2.x) / (qw * 4.0)
        let qz = (columns.1.x - columns.0.y) / (qw * 4.0)

        // Deduce euler angles
        /// yaw (z-axis rotation)
        let siny = +2.0 * (qw * qz + qx * qy)
        let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
        let yaw = atan2(siny, cosy)
        // pitch (y-axis rotation)
        let sinp = +2.0 * (qw * qy - qz * qx)
        var pitch: Float
        if abs(sinp) >= 1 {
            pitch = copysign(Float.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }
        /// roll (x-axis rotation)
        let sinr = +2.0 * (qw * qx + qy * qz)
        let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
        let roll = atan2(sinr, cosr)

        /// return array containing ypr values
        return (yaw, pitch, roll)
    }
}
