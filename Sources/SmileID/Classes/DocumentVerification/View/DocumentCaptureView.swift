import SwiftUI

struct DocumentCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DocumentCaptureViewModel
    var camera: CameraView
    init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        camera = CameraView(cameraManager: viewModel.cameraManager)
        UINavigationBar.appearance().titleTextAttributes = [.font: EpilogueFont.boldUIFont(with: 16)!,
            .foregroundColor: SmileID.theme.accent.uiColor()]

    }

    var body: some View {
        ZStack {
            camera
                .onAppear {
                    viewModel.cameraManager.switchCamera(to: .back)
                }
            DocumentOverlayView()
        } .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button {
                viewModel.resetState()
                viewModel.pauseCameraSession()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(uiImage: SmileIDResourcesHelper.ArrowLeft)
                    .padding()
            })
            .navigationBarTitle(viewModel.navTitle)
    }
}

struct DocumentCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureView(viewModel: DocumentCaptureViewModel())
    }
}

extension Color {

    func uiColor() -> UIColor {

        if #available(iOS 14.0, *) {
            return UIColor(self)
        }

        let components = self.components()
        return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {

        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
        }
        return (r, g, b, a)
    }
}
