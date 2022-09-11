import Foundation

public struct HttpMethod: RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let get: HttpMethod = "GET"
    static let post: HttpMethod = "POST"
    static let put: HttpMethod = "PUT"
    static let delete: HttpMethod = "DELETE"
}

extension HttpMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}
