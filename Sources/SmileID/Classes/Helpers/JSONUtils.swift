import Foundation

func jsonString(from object: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(object) else {
        return nil
    }

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
        return String(data: jsonData, encoding: .utf8)
    } catch {
        return nil
    }
}
