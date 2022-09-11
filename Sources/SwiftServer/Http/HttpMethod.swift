import Foundation

public struct HttpMethod: RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

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

extension HttpMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}
