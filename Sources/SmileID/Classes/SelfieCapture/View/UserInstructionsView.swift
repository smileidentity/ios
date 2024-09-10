import SwiftUI

struct UserInstructionsView: View {
    @ObservedObject var model: SelfieViewModelV2

    var body: some View {
        Text(model.directive)
            .font(.title)
            .foregroundColor(.white)
            .padding()
    }
}
