import SmileID

enum NavigationDestination: ReflectiveEquatable {
    case documentCaptureScreen(
        countryCode: String,
        documentType: String,
        captureBothSides: Bool,
        allowGalleryUpload: Bool,
        showInstructions: Bool,
        showAttribution: Bool,
        delegate: DocumentCaptureResultDelegate
    )
    case countrySelectorScreen(homeVieModel: HomeViewModel)
    case documentSelectorScreen(document: ValidDocument, homeViewModel: HomeViewModel)
}
