import SwiftUI

struct CaptureButton: View {
    let action: () -> Void
    var body: some View {
        Button(
            action: action,
            label: { Image(uiImage: SmileIDResourcesHelper.Capture) }
        )
            .frame(width: 70, height: 70, alignment: .center)
            .preferredColorScheme(.light)
    }
}

private struct CaptureButton_Previews: PreviewProvider {
    static var previews: some View {
        CaptureButton {}
    }
}
