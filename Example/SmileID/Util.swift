import Foundation
import SwiftUI

func openUrl(_ urlString: String) {
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        return
    }
    UIApplication.shared.open(url)
}
