import SwiftUI

struct InstructionsView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    @State private var debounceTimer: Timer?
    @State private var directive: String = "Instructions.Start"
    var body: some View {
        Text(SmileIDResourcesHelper.localizedString(for: directive))
            .multilineTextAlignment(.center)
            .foregroundColor(SmileID.theme.accent)
            .font(SmileID.theme.header4)
            .frame(maxWidth: 300)
            .transition(.slide)
            .onReceive(model.$directive, perform: { value in
                directive = value
            })
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionsView(model: SelfieCaptureViewModel(userId: UUID().uuidString, jobId: UUID().uuidString,
                                                       isEnroll: false))
    }
}
