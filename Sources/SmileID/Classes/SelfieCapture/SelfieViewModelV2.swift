import Foundation

public class SelfieViewModelV2: ObservableObject {
    @Published var processingState: ProcessingState?

    let useStrictMode: Bool

    var cameraManager = CameraManager(orientation: .portrait)

    init(
        useStrictMode: Bool = false
    ) {
        self.useStrictMode = useStrictMode
    }
}
