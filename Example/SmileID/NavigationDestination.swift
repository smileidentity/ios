import SmileID

enum NavigationDestination: ReflectiveEquatable {
    case documentCaptureScreen(
        countryCode: String,
        documentType: String,
        captureBothSides: Bool,
        allowGalleryUpload: Bool = true,
        showInstructions: Bool = true,
        showAttribution: Bool = true,
        delegate: DocumentCaptureResultDelegate
    )
    case countrySelectorScreen(homeVieModel: HomeViewModel)
    case documentSelectorScreen(document: ValidDocument, homeViewModel: HomeViewModel)
}
