import SwiftUI
import SmileID

class ViewFactory {
    @ViewBuilder
    func makeView(_ destination: NavigationDestination) -> some View {
        switch destination {
        case let .documentCaptureScreen(countryCode,
                                    documentType,
                                    captureBothSides,
                                    allowGalleryUpload,
                                    showInstructions,
                                    showAttribution,
                                    delegate):
            SmileID.documentVerificationScreen(
                countryCode: countryCode,
                documentType: documentType,
                captureBothSides: captureBothSides,
                allowGalleryUpload: allowGalleryUpload,
                showInstructions: showInstructions,
                showAttribution: showAttribution,
                delegate: delegate)
        case let .countrySelectorScreen(homeViewModel):
            CountryListView(homeViewModel: homeViewModel)
        case let .documentSelectorScreen(document, homeViewModel):
            IdTypeListView(document: document, homeViewModel: homeViewModel)
        }
    }
}
