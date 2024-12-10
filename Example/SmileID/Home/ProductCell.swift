import SmileID
import SwiftUI

struct ProductCell<Content: View>: View {
    let image: String
    let name: String
    let onClick: (() -> Void)?
    @ViewBuilder let content: () -> Content
    @State private var isPresented: Bool = false

    init(
        image: String,
        name: String,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.image = image
        self.name = name
        self.onClick = onClick
        self.content = content
    }

    public var body: some View {
        Button(
            action: {
                onClick?()
                isPresented = true
            },
            label: {
                VStack(spacing: 16) {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 64)
                    Text(name)
                        .multilineTextAlignment(.center)
                        .font(SmileID.theme.header4)
                        .foregroundColor(SmileID.theme.backgroundLight)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(SmileID.theme.accent)
                .cornerRadius(8)
//                .sheet(isPresented: $isPresented) {
//                    content()
//                }
                .fullScreenCover(
                    isPresented: $isPresented,
                    content: {
                        NavigationView {
                            content()
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button {
                                            isPresented = false
                                        } label: {
                                            Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                                                .foregroundColor(SmileID.theme.accent)
                                        }
                                    }
                                }
                        }
                        .environment(\.modalMode, $isPresented)
                    }
                )
            }
        )
    }
}

private struct ProductCell_Previews: PreviewProvider {
    static var previews: some View {
        ProductCell(
            image: "biometric",
            name: "SmartSelfie™ Authentication",
            content: { Text("Hello") }
        )
    }
}
