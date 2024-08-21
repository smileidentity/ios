import SwiftUI

struct FaceBoundingBoxView: View {
    @ObservedObject private(set) var model: SelfieViewModelV2

    var body: some View {
        switch model.faceGeometryState {
        case let .faceFound(faceGeometryModel):
            ZStack {
                Rectangle()
                    .path(in: CGRect(
                        x: faceGeometryModel.boundingBox.origin.x,
                        y: faceGeometryModel.boundingBox.origin.y,
                        width: faceGeometryModel.boundingBox.width,
                        height: faceGeometryModel.boundingBox.height
                    ))
                    .stroke(Color.yellow, lineWidth: 2.0)
                VStack {
                    HStack {
                        Text("\(faceGeometryModel.boundingBox.origin.x)")
                        Spacer()
                        Text("\(faceGeometryModel.boundingBox.origin.y)")
                    }
                    Spacer()
                    HStack {
                        Text("\(faceGeometryModel.boundingBox.width)")
                        Spacer()
                        Text("\(faceGeometryModel.boundingBox.height)")
                    }
                }
            }
        case .faceNotFound:
            Rectangle().fill(Color.clear)
        case .errored:
            Rectangle().fill(Color.clear)
        }
    }
}
