import SwiftUI

struct FaceBoundingBoxView: View {
    @ObservedObject private(set) var model: SelfieViewModelV2

    var body: some View {
        switch model.faceGeometryState {
        case let .faceFound(faceGeometryModel):
            Rectangle()
                .path(in: CGRect(
                    x: faceGeometryModel.boundingBox.origin.x,
                    y: faceGeometryModel.boundingBox.origin.y,
                    width: faceGeometryModel.boundingBox.width,
                    height: faceGeometryModel.boundingBox.height
                ))
                .stroke(Color.yellow, lineWidth: 2.0)
        case .faceNotFound:
            Rectangle().fill(Color.clear)
        case .errored:
            Rectangle().fill(Color.clear)
        }
    }
}
