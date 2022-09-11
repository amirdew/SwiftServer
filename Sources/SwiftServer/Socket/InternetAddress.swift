import Foundation

public typealias IPAddressV6 = in6_addr
public typealias IPAddressV4 = in_addr

/// Represents an IPv4 or an IPv6
public struct InternetAddress {
    enum Error: LocalizedError {
        case invalidAddress

        var errorDescription: String? {
            switch self {
            case .invalidAddress:
                return "The provided value is not a valid ipv4 or ipv6 address"
            }
        }
    }

    enum IP {
        case v4(IPAddressV4)
        case v6(IPAddressV6)
    }

    let ip: IP
    let value: String

    public init(_ value: String) throws {
        self.value = value
        if value.contains(".") {
            var address = IPAddressV4()
            guard inet_pton(AF_INET, value, &address) == 1 else {
                throw Error.invalidAddress
            }
            ip = .v4(address)
            return
        } else if value.contains(":") {
            var address = IPAddressV6()
            guard inet_pton(AF_INET6, value, &address) == 1 else {
                throw Error.invalidAddress
            }
            ip = .v6(address)
            return
        }
        throw Error.invalidAddress
    }
}

extension InternetAddress: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        do {
            try self.init(value)
        } catch {
            assertionFailure(error.localizedDescription)
            self = .loopback
        }
    }
}

public extension InternetAddress {
    static let loopback: Self = "127.0.0.1"
}
