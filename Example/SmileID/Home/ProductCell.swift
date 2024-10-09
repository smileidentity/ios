import SmileID
import SwiftUI

struct ProductCell: View {
    let image: String
    let name: String
    let onClick: (() -> Void)?
    @ViewBuilder let content: () -> any View
    @State private var isPresented: Bool = false

    init(
        image: String,
        name: String,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> any View
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
                .fullScreenCover(
                    isPresented: $isPresented,
                    content: {
                        AnyView(content())
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
