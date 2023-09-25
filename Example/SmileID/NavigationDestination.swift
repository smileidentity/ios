import SmileID

enum NavigationDestination: ReflectiveEquatable {
    case documentCaptureScreen(countryCode: String,
                                documentType: String,
                                allowGalleryUpload: Bool,
                                showInstructions: Bool,
                                showAttribution: Bool,
                                delegate: DocumentCaptureResultDelegate)
    case countrySelectorScreen
    case documentSelectorScreen(document: ValidDocument)
}
