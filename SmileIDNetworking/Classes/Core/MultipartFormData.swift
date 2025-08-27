import Foundation

struct MultipartFormData {
	struct Part {
		enum Payload {
			case data(Data)
			case file(URL)
		}

		var name: String
		var filename: String?
		var mimeType: String?
		var payload: Payload
	}

	let boundary: String = "----SmileIDBoundary_" + UUID().uuidString
	var parts: [Part] = []

	mutating func addData(
		_ data: Data,
		name: String,
		filename: String? = nil,
		mimeType: String? = nil
	) {
		parts.append(
			Part(
				name: name,
				filename: filename,
				mimeType: mimeType,
				payload: .data(data)
			)
		)
	}

	mutating func addFile(
		_ fileURL: URL,
		name: String,
		filename: String? = nil,
		mimeType: String? = nil
	) {
		parts.append(
			Part(
				name: name,
				filename: filename,
				mimeType: mimeType,
				payload: .file(fileURL)
			)
		)
	}

	func buildBody() -> Data {
		var body = Data()
		for part in parts {
			body.appendString("--\(boundary)\r\n")
			var disposition = "form-data; name=\"\(part.name)\""
			if let filename = part.filename {
				disposition += "; filename=\"\(filename)\""
			}
			body.appendString("Content-Disposition: \(disposition)\r\n")
			if let mime = part.mimeType {
				body.appendString("Content-Type: \(mime)\r\n")
			}
			body.appendString("\r\n")
			switch part.payload {
			case .data(let data): body.append(data)
			case .file(let url):
				if let data = try? Data(contentsOf: url) {
					body.append(data)
				}
			}
			body.appendString("\r\n")
		}
		body.appendString("--\(boundary)--\r\n")
		return body
	}
}

extension Data {
	fileprivate mutating func appendString(_ string: String) {
		if let data = string.data(using: .utf8) {
			append(data)
		}
	}
}
