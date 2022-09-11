import Foundation

public struct HttpMethod: RawRepresentable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }
}

extension HttpMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension HttpMethod {
    static let get: HttpMethod = "GET"
    static let head: HttpMethod = "HEAD"
    static let connect: HttpMethod = "CONNECT"
    static let options: HttpMethod = "OPTIONS"
    static let trace: HttpMethod = "TRACE"
    static let post: HttpMethod = "POST"
    static let put: HttpMethod = "PUT"
    static let delete: HttpMethod = "DELETE"
    static let patch: HttpMethod = "PATCH"
}
