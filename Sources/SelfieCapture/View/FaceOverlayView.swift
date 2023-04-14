import Foundation
import SwiftUI

struct FaceOverlayView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 5) {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            FaceShape()
                                .blendMode(.destinationOut)
                                .frame(width: geometry.size.width*0.6,
                                       height: geometry.size.width*0.6/0.7)

                        )
                        .overlay(FaceShape()
                            .stroke(Color.digitalBlueOpacity40,
                                    lineWidth: 10)
                                .frame(width: geometry.size.width*0.6,
                                       height: geometry.size.width*0.6/0.7))
                        .overlay(FaceShape()
                            .trim(from: 0, to: model.progress)
                            .stroke(Color.successGreen, style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round))
                                .frame(width: geometry.size.width*0.6,
                                       height: geometry.size.width*0.6/0.7)
                                .animation(.easeOut, value: model.progress)
                        )
                }.padding(.top, -200)
                InstructionsView(model: model)
                    .padding(.top, -((geometry.size.width*0.6/0.7)/2) - 100)

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
