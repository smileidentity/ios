import Foundation
import SwiftUI

struct FaceOverlayView: View {
    @State var agentMode = false
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
                            .stroke(SmileID.theme.accent.opacity(0.4),
                                    lineWidth: 10)
                                .frame(width: faceWidth,
                                       height: faceHeight))
                        .overlay(FaceShape()
                            .trim(from: 0, to: model.progress)
                            .stroke(SmileID.theme.success, style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round))
                                .frame(width: faceWidth,
                                       height: faceHeight)
                                    .animation(.easeOut, value: model.progress)
                        )

                }
                .padding(.top, -200)
                .scaleEffect(1.2, anchor: .top)
                InstructionsView(model: model)
                    .padding(.top, -((faceWidth)/2))
                HStack(spacing: 10) {
                    Text("Agent Mode")
                        .foregroundColor(agentMode ? SmileID.theme.backgroundMain : SmileID.theme.accent)
                        .font(SmileID.theme.header4)
                    Toggle("", isOn: $model.agentMode).labelsHidden()
                }
                    .frame(width: 188, height: 46)
                    .background(agentMode ? SmileID.theme.accent : SmileID.theme.backgroundMain)
                    .cornerRadius(23)
                    .shadow(radius: 23)
                    .padding(.bottom, 35)
                    .animation(.default)

            }
        }
    }
}

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}
