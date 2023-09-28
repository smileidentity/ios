import Foundation
import UIKit
import SwiftUI

protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage)
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    weak var delegate: ImagePickerDelegate?

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ImagePicker>
    ) -> UIImagePickerController {

        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: UIViewControllerRepresentableContext<ImagePicker>
    ) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator:
        NSObject,
        UIImagePickerControllerDelegate,
        UINavigationControllerDelegate {

        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.delegate?.didSelect(image: image)
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
