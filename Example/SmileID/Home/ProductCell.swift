import SmileID
import SwiftUI

struct ProductCell: View {
  let product: SmileIDProduct

  public var body: some View {
    VStack(spacing: 16) {
      Image(product.image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 48, height: 64)
      Text(product.name)
        .multilineTextAlignment(.center)
        .font(SmileID.theme.header4)
        .foregroundColor(SmileID.theme.backgroundLight)
      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SmileID.theme.accent)
    .cornerRadius(8)
  }
}

private struct ProductCell_Previews: PreviewProvider {
  static var previews: some View {
    ProductCell(product: .smartSelfieAuthentication)
  }
}
