import SwiftUI

struct ModalPresenter<ModalContent: View>: View {
    @Binding var isPresented: Bool
    let modalContent: ModalContent
    var centered: Bool

    init(
        isPresented: Binding<Bool> = .constant(true),
        centered: Bool = true,
        @ViewBuilder content: () -> ModalContent
    ) {
        self._isPresented = isPresented
        self.centered = centered
        modalContent = content()
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
                    if !centered {
                        Spacer()
                    }
                    modalContent
                }
                    .padding(.horizontal, 20)
                    .padding(.bottom, centered ? 0 : 50)
            }
        }
    }
}
