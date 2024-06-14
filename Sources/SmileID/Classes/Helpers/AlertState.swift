import Foundation

struct AlertState: Identifiable {
    let id: UUID
    let message: String?
    let title: String
    
    init(id: UUID = UUID(), message: String? = nil, title: String) {
        self.id = id
        self.message = message
        self.title = title
    }
}
