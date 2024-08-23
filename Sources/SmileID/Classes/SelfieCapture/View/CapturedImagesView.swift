import SwiftUI

struct CapturedImagesView: View {
    var model: SelfieViewModelV2
    @State private var images: [UIImage] = []

    var body: some View {
        NavigationView {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading) {
                    if let selfieURL = model.selfieImage,
                       let selfieImage = loadImage(from: selfieURL) {
                        Image(uiImage: selfieImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 148, height: 320)
                    } else {
                        Text("No selfie image")
                            .font(.title)
                    }
                    if !images.isEmpty {
                        HStack {
                            ForEach(images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 148, height: 320)
                            }
                        }
                    } else {
                        Text("No liveness images")
                            .font(.title)
                    }
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 342)
                .navigationBarTitle(Text("Captured Images"))
                .onAppear {
                    loadImages()
                }
            }
        }
    }

    private func loadImages() {
        images = model.livenessImages.compactMap {
            loadImage(from: $0)
        }
    }

    private func loadImage(from url: URL) -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}
