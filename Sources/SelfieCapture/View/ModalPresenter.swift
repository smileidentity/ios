import SwiftUI

struct ModalPresenter<ModalContent: View>: View {
    @Binding var isPresented: Bool
    let modalContent: ModalContent

    init(isPresented: Binding<Bool> = .constant(true), @ViewBuilder content: () -> ModalContent) {
        self._isPresented = isPresented
        self.modalContent = content()
    }

    var body: some View {
        ZStack {
            if isPresented {
                Color.white
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
                .padding(.bottom, 50)
            }
        }
    }
}
