import SwiftUI

struct DocumentShapedView: View {
    let borderColor: Color
    
    init(borderColor: Color = .white) {
        self.borderColor = borderColor
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 3)
                .aspectRatio(1.586, contentMode: .fit)
                .scaleEffect(0.8)
        }
				.edgesIgnoringSafeArea(.all)
    }
}
