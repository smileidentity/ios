import Foundation
import Combine
import SwiftUI

struct FaceOverlayView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    var body: some View {
        GeometryReader { geometry in
            let faceWidth = geometry.size.width * 0.6
            let faceHeight = faceWidth / 0.7

            VStack(spacing: 5) {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            FaceShape()
                                .blendMode(.destinationOut)
                                .frame(width: faceWidth, height: faceHeight)
                                .background(GeometryReader { localGeometry in
                                    Color.clear.onReceive(
                                        Just(localGeometry.frame(in: .global))
                                    ) { globalFrame in
                                        let globalOriginX = globalFrame.origin.x
                                        let faceOriginX = model.faceLayoutGuideFrame.origin.x
                                        if globalOriginX != faceOriginX {
                                            let window = UIApplication
                                                .shared
                                                .connectedScenes
                                                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                                                .last { $0.isKeyWindow }
                                            if let rootView = window {
                                                // Geometry reader's .global returns the frame in
                                                // the screen's coordinate system.
                                                let screenHeight = rootView.screen.bounds.height
                                                let geometryHeight = geometry.size.height
                                                let safeArea = screenHeight - geometryHeight
                                                model.faceLayoutGuideFrame = CGRect(
                                                    origin: CGPoint(
                                                        x: globalOriginX,
                                                        y: globalFrame.origin.y - safeArea
                                                    ),
                                                    size: globalFrame.size
                                                )
                                            }
                                        }
                                    }
                                })
                        )
                        .overlay(
                            FaceShape()
                                .stroke(
                                    SmileID.theme.accent.opacity(0.4),
                                    lineWidth: 10
                                )
                                .frame(width: faceWidth, height: faceHeight))
                        .overlay(
                            FaceShape()
                                .trim(from: 0, to: model.progress)
                                .stroke(
                                    SmileID.theme.success,
                                    style: StrokeStyle(
                                        lineWidth: 10,
                                        lineCap: .round
                                    )
                                )
                                .frame(width: faceWidth, height: faceHeight)
                                .animation(.easeOut, value: model.progress)
                        )
                }
                    .padding(.top, -200)
                    .scaleEffect(1.2, anchor: .top)
                InstructionsView(model: model)
                    .padding(.top, -((faceWidth) / 2))
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
}
