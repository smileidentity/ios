import Foundation
import Combine
import SwiftUI

struct FaceOverlayView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel

    private let strokeWidth = 10
    private let faceShape = FaceShape().scale(x: 0.85, y: 0.75).offset(y: -25)
    private let bgColor = Color.white.opacity(0.8)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
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
//                    .background(GeometryReader { localGeometry in
//                        Color.clear.onReceive(
//                            // The delay is needed for when the view could be going
//                            // through a transition (i.e. resizing because the keyboard
//                            // is in the process of getting dismissed)
//                            Just(localGeometry.frame(in: .global))
//                                .delay(for: 0.5, scheduler: DispatchQueue.main)
//                        ) { globalFrame in
//                            let globalOriginX = globalFrame.origin.x
//                            let faceOriginX = model.faceLayoutGuideFrame.origin.x
//                            if globalOriginX != faceOriginX {
//                                let window = UIApplication
//                                    .shared
//                                    .connectedScenes
//                                    .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
//                                    .last { $0.isKeyWindow }
//                                if let rootView = window {
//                                    // Geometry reader's .global returns the frame in
//                                    // the screen's coordinate system.
//                                    let screenHeight = rootView.screen.bounds.height
//                                    let geometryHeight = geometry.size.height
//                                    let safeArea = screenHeight - geometryHeight
//                                    model.faceLayoutGuideFrame = CGRect(
//                                        origin: CGPoint(
//                                            x: globalOriginX,
//                                            y: globalFrame.origin.y - safeArea
//                                        ),
//                                        size: globalFrame.size
//                                    )
//                                }
//                            }
//                        }
//                    })

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
                    .frame(width: geometry.size.width)
                    .background(bgColor)
            }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
