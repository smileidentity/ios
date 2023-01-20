import SwiftUI
import Combine

public struct SelfieCaptureView: View {
    @StateObject private var viewModel = SelfieCaptureViewModel()
    let camera = CameraView()
    private weak var captureResult: SmartSelfieResult?
    private var dividerWidth = UIScreen.main.bounds.width - 40
    private weak var delegate: SmartSelfieResult?
    private init() {}
    public init(delegate: SmartSelfieResult) {
        self.init()
        self.delegate = delegate
    }

    // TO-DO: Clean up selfie capture view. Make UI Configurable
    public var body: some View {
        GeometryReader { geometry in
            let ovalSize = ovalSize(from: geometry)
            VStack(spacing: 20) {
                ZStack {
                    camera
                        .clipShape(Ellipse())
                        .onAppear {
                            viewModel.captureResultDelegate = delegate
                            viewModel.faceLayoutGuideFrame =
                            CGRect(origin: .zero,
                                   size: ovalSize)
                            viewModel.viewDelegate = camera.preview
                        }
                    ProgressView(model: viewModel)
                }
                .frame(width: ovalSize.width,
                       height: ovalSize.height)
                InstructionsView(model: viewModel)
                Divider()
                    .frame(width: dividerWidth)
                HStack {
                    Image(systemName: "info.circle.fill")
                        .frame(width: 32, height: 32)
                    Text("Put your face inside the oval frame and wait until it turns blue.")
                        .font(.system(size: 12))
                }.frame(maxWidth: 250)
                Spacer()
                Image("SmileEmblem", bundle: .module)
            }.padding(.top, 90)
                .frame(width: geometry.size.width,
                       height: geometry.size.height)

        }
    }

    private func ovalSize(from geometry: GeometryProxy) -> CGSize {
        return CGSize(width: geometry.size.width * 0.7,
                      height: geometry.size.width * 0.7 / (3/3.5))
    }
}

struct ProgressView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    let emptyStateColor = Color(red: 0.94, green: 0.95, blue: 0.98)
    let fillCollor = Color(red: 0.09, green: 0.639, blue: 0.863)

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(emptyStateColor,
                        lineWidth: 10)
            Ellipse()
                .trim(from: 0, to: model.progress)
                .stroke(fillCollor, style: StrokeStyle(
                    lineWidth: 10,
                    lineCap: .round))
                .animation(.easeOut, value: model.progress)
        }
    }

}
