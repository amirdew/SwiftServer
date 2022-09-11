import Foundation

public struct HttpHeaderKey: RawRepresentable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }

    public var description: String {
        rawValue
    }
}

extension HttpHeaderKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension HttpHeaderKey {
    static let contentType: HttpHeaderKey = "content-type"
    static let connection: HttpHeaderKey = "connection"
    static let date: HttpHeaderKey = "date"
    static let server: HttpHeaderKey = "server"
    static let contentLength: HttpHeaderKey = "content-length"
}
