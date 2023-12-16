import Foundation
import Combine
import SwiftUI

struct FaceOverlayView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel

    private let strokeWidth = 10
    private let faceShape = FaceShape().scale(x: 0.85, y: 0.75).offset(y: -25)
    private let bgColor = Color.white.opacity(0.8)

    init(model: SelfieCaptureViewModel) {
        self.model = model
        let window = UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
        if let rootView = window {
            model.faceLayoutGuideFrame = rootView.screen.bounds
        } else {
            print("window was (unexpectedly) null -- selfie capture will not work")
        }
    }

    var body: some View {
        let view = VStack(spacing: 0) {
            bgColor
                .cutout(faceShape)
                .overlay(faceShape.stroke(SmileID.theme.accent.opacity(0.4), lineWidth: 10))
                .overlay(
                    faceShape
                        .trim(from: 0, to: model.progress)
                        .stroke(
                            SmileID.theme.success,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .animation(.easeOut, value: model.progress)
                )

            VStack(spacing: 25) {
                InstructionsView(model: model)

                if model.allowsAgentMode {
                    let agentMode = model.agentMode
                    HStack(spacing: 10) {
                        Text("Agent Mode")
                            .foregroundColor(
                                agentMode ? SmileID.theme.backgroundMain : SmileID.theme.accent
                            )
                            .font(SmileID.theme.header4)
                        Toggle("", isOn: $model.agentMode).labelsHidden()
                    }
                        .frame(width: 188, height: 48)
                        .background(agentMode ? SmileID.theme.accent : SmileID.theme.backgroundMain)
                        .cornerRadius(25)
                        .shadow(radius: 25)
                        .padding(.bottom, 25)
                        .animation(.default)
                }
            }
                .frame(maxWidth: .infinity)
                .background(bgColor)
        }

        if #available(iOS 14.0, *) {
            view.ignoresSafeArea(.keyboard)
        } else {
            view
        }
    }
}
