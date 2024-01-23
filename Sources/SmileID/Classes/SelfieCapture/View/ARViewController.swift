import UIKit
import SwiftUI
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    private let smileThreshold = 0.5
    internal var delegate: ARKitSmileDelegate?
    private var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView(frame: view.frame)
        sceneView.rendersCameraGrain = false
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView?.session.pause()
        delegate?.onSmiling(isSmiling: false)
    }

    // ARSCNViewDelegate methods

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.transparency = 0.0
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            // No face detected
            return
        }
        // We could use faceAnchor as an alternative to FaceDetector - it has roll/pitch/yaw info
        // as well as bounding box info (faceAnchor.transform)
        // However, we use ARKit only for Smile probability currently

        if let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
        }
        let smileLeft = (faceAnchor.blendShapes[.mouthSmileLeft] ?? 0).doubleValue
        let smileRight = (faceAnchor.blendShapes[.mouthSmileRight] ?? 0).doubleValue
        let isSmileLeft = smileLeft > smileThreshold
        let isSmileRight = smileRight > smileThreshold
        delegate?.onSmiling(isSmiling: isSmileLeft || isSmileRight)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        delegate?.onARKitFrame(frame: frame)
    }
}

struct ARView: UIViewControllerRepresentable {
    let viewController: ARViewController
    typealias UIViewControllerType = ARViewController

    init(delegate: ARKitSmileDelegate) {
        viewController = ARViewController()
        viewController.delegate = delegate
    }

    func makeUIViewController(context: Context) -> ARViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

protocol ARKitSmileDelegate {
    func onSmiling(isSmiling: Bool)
    func onARKitFrame(frame: ARFrame)
}
