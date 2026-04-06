import Foundation

import Compression

// MARK: - Error

enum TransformError: LocalizedError {
    case invalidInput(String)

    var errorDescription: String? {
        if case .invalidInput(let msg) = self { return msg }
        return nil
    }
}

// MARK: - Categories

enum OperationCategory: String, CaseIterable, Identifiable {
    case base64
    case url
    case saml
    case prettyPrint

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .base64:            return "Base64"
        case .url:               return "URL"
        case .saml:              return "SAML / SSO"
        case .prettyPrint:       return "Pretty Print"
        }
    }

    var operations: [Operation] {
        Operation.allCases.filter { $0.category == self }
    }
}

// MARK: - Operations

enum Operation: String, CaseIterable, Identifiable {
    case base64Encode
    case base64Decode
    case base64urlEncode
    case base64urlDecode
    case urlEncode
    case urlDecode
    case samlDecode
    case jsonPrettyPrint
    case xmlPrettyPrint

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .base64Encode:          return "Base64 Encode"
        case .base64Decode:          return "Base64 Decode"
        case .base64urlEncode:       return "Base64URL Encode"
        case .base64urlDecode:       return "Base64URL Decode"
        case .urlEncode:             return "URL Encode"
        case .urlDecode:             return "URL Decode"
        case .samlDecode:            return "SAML Decode"
        case .jsonPrettyPrint:       return "JSON Pretty Print"
        case .xmlPrettyPrint:        return "XML Pretty Print"
        }
    }

    var category: OperationCategory {
        switch self {
        case .base64Encode, .base64Decode, .base64urlEncode, .base64urlDecode:
            return .base64
        case .urlEncode, .urlDecode:
            return .url
        case .samlDecode:
            return .saml
        case .jsonPrettyPrint, .xmlPrettyPrint:
            return .prettyPrint
        }
    }

    func transform(_ input: String) -> Result<String, Error> {
        do { return .success(try apply(input)) }
        catch { return .failure(error) }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func apply(_ input: String) throws -> String {
        switch self {

        // MARK: Base64
        case .base64Encode:
            return Data(input.utf8).base64EncodedString()

        case .base64Decode:
            let padded = b64Padded(input.trimmingCharacters(in: .whitespacesAndNewlines))
            guard let data = Data(base64Encoded: padded, options: .ignoreUnknownCharacters) else {
                throw TransformError.invalidInput("Invalid Base64 input")
            }
            guard let s = String(data: data, encoding: .utf8) else {
                throw TransformError.invalidInput("Decoded bytes are not valid UTF-8")
            }
            return s

        case .base64urlEncode:
            return Data(input.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")

        case .base64urlDecode:
            let fixed = input.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = b64Padded(fixed)
            guard let data = Data(base64Encoded: padded, options: .ignoreUnknownCharacters) else {
                throw TransformError.invalidInput("Invalid Base64URL input")
            }
            guard let s = String(data: data, encoding: .utf8) else {
                throw TransformError.invalidInput("Decoded bytes are not valid UTF-8")
            }
            return s

        // MARK: URL
        case .urlEncode:
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~")
            guard let encoded = input.addingPercentEncoding(withAllowedCharacters: allowed) else {
                throw TransformError.invalidInput("Encoding failed")
            }
            return encoded

        case .urlDecode:
            guard let decoded = input.removingPercentEncoding else {
                throw TransformError.invalidInput("Invalid percent-encoded input")
            }
            return decoded

        // MARK: SAML
        case .samlDecode:
            let padded = b64Padded(input.trimmingCharacters(in: .whitespacesAndNewlines))
            guard let decoded = Data(base64Encoded: padded, options: .ignoreUnknownCharacters) else {
                throw TransformError.invalidInput("Invalid Base64 in SAML token")
            }
            let xmlData: Data
            if let inflated = try? rawInflate(decoded) {
                xmlData = inflated
            } else {
                xmlData = decoded
            }
            guard let xmlString = String(data: xmlData, encoding: .utf8) else {
                throw TransformError.invalidInput("Decoded data is not valid UTF-8")
            }
            let doc = try XMLDocument(xmlString: xmlString, options: [.nodePreserveAll])
            return doc.xmlString(options: [.nodePrettyPrint])

        // MARK: Pretty Print
        case .jsonPrettyPrint:
            guard let data = input.data(using: .utf8) else {
                throw TransformError.invalidInput("Invalid UTF-8 input")
            }
            let obj = try JSONSerialization.jsonObject(with: data)
            let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
            guard let s = String(data: pretty, encoding: .utf8) else {
                throw TransformError.invalidInput("Failed to convert JSON to string")
            }
            return s

        case .xmlPrettyPrint:
            let doc = try XMLDocument(xmlString: input, options: [.nodePreserveAll])
            return doc.xmlString(options: [.nodePrettyPrint])

        }
    }
}

// MARK: - Auto-format output

func autoFormat(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    // Try JSON
    if let data = trimmed.data(using: .utf8),
       let obj = try? JSONSerialization.jsonObject(with: data),
       let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
       let s = String(data: pretty, encoding: .utf8) {
        return s
    }

    // Try XML
    if (trimmed.hasPrefix("<") || trimmed.hasPrefix("<?xml")),
       let doc = try? XMLDocument(xmlString: trimmed, options: [.nodePreserveAll]) {
        return doc.xmlString(options: [.nodePrettyPrint])
    }

    return text
}

// MARK: - Base64 padding

private func b64Padded(_ s: String) -> String {
    let r = s.count % 4
    return r == 0 ? s : s + String(repeating: "=", count: 4 - r)
}

// MARK: - Raw DEFLATE (for SAML)

private func rawInflate(_ input: Data) throws -> Data {
    var capacity = max(input.count * 10, 4096)
    for _ in 0..<6 {
        var output = Data(count: capacity)
        let written: Int = input.withUnsafeBytes { src in
            output.withUnsafeMutableBytes { dst in
                guard let s = src.baseAddress, let d = dst.baseAddress else { return 0 }
                return compression_decode_buffer(
                    d.assumingMemoryBound(to: UInt8.self), capacity,
                    s.assumingMemoryBound(to: UInt8.self), input.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        if written > 0 { return Data(output.prefix(written)) }
        capacity *= 4
    }
    throw TransformError.invalidInput("Decompression failed — data may not be raw DEFLATE")
}


