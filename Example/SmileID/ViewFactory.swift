import SwiftUI
import SmileID

class ViewFactory {
    @ViewBuilder
    func makeView(_ destination: NavigationDestination) -> some View {
        switch destination {
        case let .documentCaptureScreen(countryCode,
                                    documentType,
                                    allowGalleryUpload,
                                    showInstructions,
                                    showAttribution,
                                    delegate):
            SmileID.documentVerificationScreen(
                countryCode: countryCode,
                documentType: documentType,
                allowGalleryUpload: allowGalleryUpload,
                showInstructions: showInstructions,
                showAttribution: showAttribution,
                delegate: delegate)
        case .countrySelectorScreen:
            CountryListView()
        case let .documentSelectorScreen(document):
            IdTypeListView(document: document)
        }
    }
}
