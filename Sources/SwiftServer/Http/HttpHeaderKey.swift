import Foundation

public struct HttpHeaderKey: RawRepresentable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }

    static let contentType: HttpHeaderKey = "content-type"
    static let connection: HttpHeaderKey = "connection"
    static let server: HttpHeaderKey = "server"
    static let contentLength: HttpHeaderKey = "content-length"
}

extension HttpHeaderKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}
