import SwiftUI

struct SmileIDInstructionsScreen: View {
	var body: some View {
		VStack {
			ScrollView(.vertical) {
				// Image(uiImage: <#T##UIImage#>)
				
				Text("Some header here")
					.font(.title)
				Text("Some subtitle here")
				Spacer()
			}

			VStack {
				Button("Continue") {
					print("continue button")
				}
				.buttonStyle(SmileIDButtonStyle())

				Button("Continue") {
					print("continue button")
				}
				.buttonStyle(SmileIDButtonStyle())
			}
			.padding()
		}
	}
}

#if DEBUG
#Preview {
	NavigationView {
		SmileIDInstructionsScreen()
	}
}
#endif
