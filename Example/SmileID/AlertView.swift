import SwiftUI
import SmileID

struct AlertView: View {
    let icon: Image
    let title: String
    let description: String
    let buttonTitle: String
    let onClick: () -> Void
    
    var body: some View {
        VStack {
            icon
                .resizable()
                .frame(width: 40, height: 40)
                .padding(.bottom, 10)
                .foregroundColor(SmileID.theme.accent)
            
            Text(title)
                .font(SmileID.theme.header4)
                .padding(.bottom, 5)
                .foregroundColor(SmileID.theme.accent)
            
            Text(description)
                .font(SmileID.theme.body)
                .foregroundColor(SmileID.theme.onLight)                
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            Button(action: {onClick()}) {
                Text(buttonTitle)
                    .font(SmileID.theme.header4)
                    .foregroundColor(.white)
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background(SmileID.theme.accent)
                    .cornerRadius(60)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}
