import SmileID
import SwiftUI

struct ProductCell: View {
    let image: String
    let name: String
    let onClick: (() -> Void)?
    let onNoConnection: (() -> Void)?
    var requiresConnection: Bool = false
    @ViewBuilder let content: () -> any View
    @State private var isPresented: Bool = false
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    init(
        image: String,
        name: String,
        onClick: (() -> Void)? = nil,
        onNoConnection: (() -> Void)? = nil,
        requiresConnection: Bool? = true,
        @ViewBuilder content: @escaping () -> any View
    ) {
        self.image = image
        self.name = name
        self.onClick = onClick
        self.onNoConnection = onNoConnection
        self.requiresConnection = requiresConnection ?? false
        self.content = content
    }

    public var body: some View {
        Button(
            action: {
                if networkMonitor.isConnected || !requiresConnection {
                    onClick?()
                    isPresented = true
                } else {
                    onNoConnection?()
                }
            },
            label: {
                VStack(spacing: 16) {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42)
                    Text(name)
                        .multilineTextAlignment(.center)
                        .font(SmileID.theme.header4)
                        .foregroundColor(SmileID.theme.backgroundLight)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(SmileID.theme.accent)
                .cornerRadius(8)
                .sheet(isPresented: $isPresented, content: { AnyView(content()) })
            }
        )
    }
}

private struct ProductCell_Previews: PreviewProvider {
    static var previews: some View {
        ProductCell(
            image: "userauth",
            name: "SmartSelfie™ Authentication",
            content: { Text("Hello") }
        )
    }
}
