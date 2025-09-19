import SwiftUI

public struct CameraView<Overlay: View>: View {
  @ObservedObject private var viewModel: CameraViewModel
  @Backport.StateObject private var orientationObserver = DeviceOrientationObserver()
  private let overlay: () -> Overlay

  public init(
    viewModel: CameraViewModel,
    @ViewBuilder overlay: @escaping () -> Overlay
  ) {
    self.viewModel = viewModel
    self.overlay = overlay
  }

  public var body: some View {
    ZStack {
      CameraPreviewContainer(session: viewModel.session)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onReceive(orientationObserver.$videoOrientation) { orientation in
          viewModel.setOrientation(orientation)
        }
      overlay()
    }
    .alert(
      isPresented: Binding(
        get: { viewModel.lastError != nil },
        set: { presented in
          if !presented {
            viewModel.clearLastError()
          }
        }
      ),
      content: {
        Alert(
          title: Text("Camera Error"),
          message: Text(viewModel.lastError?.localizedDescription ?? "Unknown error"),
          dismissButton: .default(Text("OK"), action: {
            viewModel.clearLastError()
          })
        )
      }
    )
  }
}
