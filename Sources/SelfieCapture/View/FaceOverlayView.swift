import Foundation
import SwiftUI

struct FaceOverlayView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    var body: some View {
        GeometryReader { geometry in
            let faceWidth = geometry.size.width*0.6
            let faceHeight = faceWidth/0.7

            VStack(spacing: 5) {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            FaceShape()
                                .blendMode(.destinationOut)
                                .frame(width: faceWidth,
                                       height: faceHeight)

                        )
                        .overlay(FaceShape()
                            .stroke(SmileIdentity.theme.accent.opacity(0.4),
                                    lineWidth: 10)
                                .frame(width: faceWidth,
                                       height: faceHeight))
                        .overlay(FaceShape()
                            .trim(from: 0, to: model.progress)
                            .stroke(SmileIdentity.theme.success, style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round))
                                .frame(width: faceWidth,
                                       height: faceHeight)
                                .animation(.easeOut, value: model.progress)
                        )
                }.padding(.top, -200)
                InstructionsView(model: model)
                    .padding(.top, -((faceWidth)/2) - 100)

            }
        }
    }
}

struct FaceOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        FaceOverlayView(model: SelfieCaptureViewModel(userId: UUID().uuidString,
                                                      sessionId: UUID().uuidString,
                                                      isEnroll: false))
    }
}
