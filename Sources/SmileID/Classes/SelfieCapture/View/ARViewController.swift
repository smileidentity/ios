import UIKit
import SwiftUI
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate  {

    var sceneView: ARSCNView!
    private var detectedFaces = 0
    private var faceView: UIView?
    weak var model: SelfieCaptureViewModel?
    private var faceNode: SCNNode?
    private var virtualPhoneNode: SCNNode?

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
        self.faceNode = node
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            model?.perform(action: .noFaceDetected)
            return
        }
        updateFeatures(for: faceAnchor)
        let projectedPoints = faceAnchor.verticeAndProjection(to: sceneView)
        let boundingBox = faceBoundingBox(for: projectedPoints)
        let angles = getEulerAngles(from: faceAnchor)
        let faceObservationModel = FaceGeometryModel(boundingBox: boundingBox, roll: angles.roll as NSNumber, yaw: angles.yaw as NSNumber)
        model?.perform(action: .faceObservationDetected(faceObservationModel))
    }

    func getEulerAngles(from faceAnchor: ARFaceAnchor) -> (roll: Float, pitch: Float, yaw: Float) {
        // Extract the 4x4 transform matrix from the face anchor.
        let transformMatrix = faceAnchor.transform

        // Convert the transform matrix to a quaternion.
        let orientationQuat = simd_quatf(transformMatrix)

        // Convert the quaternion to roll, pitch, yaw.
        let pitch = asin(2 * orientationQuat.vector.y * orientationQuat.vector.w - 2 * orientationQuat.vector.x * orientationQuat.vector.z)
        let yaw = atan2(2 * orientationQuat.vector.x * orientationQuat.vector.w - 2 * orientationQuat.vector.y * orientationQuat.vector.z, 1 - 2 * pow(orientationQuat.vector.x, 2) - 2 * pow(orientationQuat.vector.y, 2))
        let roll = atan2(2 * orientationQuat.vector.x * orientationQuat.vector.y - 2 * orientationQuat.vector.z * orientationQuat.vector.w, 1 - 2 * pow(orientationQuat.vector.y, 2) - 2 * pow(orientationQuat.vector.z, 2))

        // Return as a tuple.
        return (roll, pitch, yaw)
    }

    private func faceBoundingBox(for projectedPoints: [ARFaceAnchor.VerticesAndProjection]) -> CGRect {
        let allXs = projectedPoints.map { $0.projected.x }
        let allYs = projectedPoints.map { $0.projected.y }

        let minX = allXs.min() ?? 0
        let maxX = allXs.max() ?? 0
        let minY = allYs.min() ?? 0
        let maxY = allYs.max() ?? 0
        let boundingBox = CGRect(x: minX, y: minY, width: (maxX - minX) * 0.8, height: (maxY - minY) * 0.8)
        DispatchQueue.main.async {
            self.faceView?.frame = boundingBox
        }

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
            let projectedPoints = faceAnchor.verticeAndProjection(to: sceneView)
            let boundingBox = faceBoundingBox(for: projectedPoints)
            let angles = getEulerAngles(from: faceAnchor)
            let faceObservationModel = FaceGeometryModel(boundingBox: boundingBox, roll: angles.roll as NSNumber, yaw: angles.yaw as NSNumber)
            model?.perform(action: .faceObservationDetected(faceObservationModel))
        } else {
            model?.perform(action: .noFaceDetected)
            return
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARFaceAnchor {
            detectedFaces -= 1
            faceView?.frame = .zero
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        NotificationCenter.default.post(name:  NSNotification.Name(rawValue: "UpdateARFrame"), object: nil, userInfo: ["frame" : frame])
    }


    private func updateFeatures(for faceAnchor: ARFaceAnchor) {
        if let faceGeometry = faceNode?.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
        }
        let smileLeft = faceAnchor.blendShapes[.mouthSmileLeft]
        let smileRight = faceAnchor.blendShapes[.mouthSmileRight]

        if let smileL = smileLeft, let smileR = smileRight, smileL.floatValue > 0.5 && smileR.floatValue > 0.5 {
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
        self.preview = ARViewController()
    }
    func makeUIViewController(context: Context) -> ARViewController {
       return preview
    }
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}


extension ARFaceAnchor{
    // struct to store the 3d vertex and the 2d projection point
    struct VerticesAndProjection {
        var vertex: SIMD3<Float>
        var projected: CGPoint
    }

    // return a struct with vertices and projection
    func verticeAndProjection(to view: ARSCNView) -> [VerticesAndProjection]{

        let points = geometry.vertices.compactMap({ (vertex) -> VerticesAndProjection? in

            let col = SIMD4<Float>(SCNVector4())
            let pos = SIMD4<Float>(SCNVector4(vertex.x, vertex.y, vertex.z, 1))

            let pworld = transform * simd_float4x4(col, col, col, pos)

            let vect = view.projectPoint(SCNVector3(pworld.position.x, pworld.position.y, pworld.position.z))

            let p = CGPoint(x: CGFloat(vect.x), y: CGFloat(vect.y))
            return VerticesAndProjection(vertex:vertex, projected: p)
        })

        return points
    }
}

extension matrix_float4x4 {

    /// Get the position of the transform matrix.
    public var position: SCNVector3 {
        get{
            return SCNVector3(self[3][0], self[3][1], self[3][2])
        }
    }
}
