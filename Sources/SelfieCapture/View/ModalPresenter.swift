import SwiftUI

struct ModalPresenter<ModalContent: View>: View {
    @Binding var isPresented: Bool
    let modalContent: ModalContent

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> ModalContent) {
        self._isPresented = isPresented
        self.modalContent = content()
    }

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.65)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                VStack {
                    Spacer()
                    modalContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(AnyTransition.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}
