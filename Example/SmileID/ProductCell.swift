import SwiftUI
import SmileID

struct ProductCell: View {
    let image: String
    let name: String
    let onClick: (() -> Void)?
    let content: any View
    @State private var isPresented: Bool = false

    init(
        image: String,
        name: String,
        onClick: (() -> Void)? = nil,
        content: any View
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
                VStack(spacing: 24) {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48)
                    Text(name)
                        .multilineTextAlignment(.center)
                        .font(SmileID.theme.header4)
                        .foregroundColor(SmileID.theme.backgroundLight)
                }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(SmileID.theme.accent)
                    .cornerRadius(8)
                    .sheet(isPresented: $isPresented, content: { AnyView(content) })
            }
        )
    }
}

struct ProductCell_Previews: PreviewProvider {
    static var previews: some View {
        ProductCell(
            image: "userauth",
            name: "SmartSelfie™ Authentication",
            content: Text("Hello")
        )
    }
}
