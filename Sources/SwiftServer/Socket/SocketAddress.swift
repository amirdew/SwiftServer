import Foundation

public typealias SocketAddressV6 = sockaddr_in6
public typealias SocketAddressV4 = sockaddr_in

/// Represents a socket address which contains the port and the IP
public struct SocketAddress {
    let address: InternetAddress
    let port: UInt16
    let data: Data

    init(address: InternetAddress, port: UInt16) {
        self.address = address
        self.port = port

        switch address.ip {
        case .v4(let ip):
            var socketAddress = SocketAddressV4()
            socketAddress.sin_len = UInt8(MemoryLayout<SocketAddressV4>.stride)
            socketAddress.sin_family = sa_family_t(AF_INET)
            socketAddress.sin_port = port.bigEndian
            socketAddress.sin_addr = ip
            self.data = Data(bytes: &socketAddress, count: MemoryLayout<SocketAddressV4>.stride)
        case .v6(let ip):
            var socketAddress = SocketAddressV6()
            socketAddress.sin6_len = UInt8(MemoryLayout<SocketAddressV6>.stride)
            socketAddress.sin6_family = sa_family_t(AF_INET6)
            socketAddress.sin6_port = port.bigEndian
            socketAddress.sin6_addr = ip
            self.data = Data(bytes: &socketAddress, count: MemoryLayout<SocketAddressV6>.stride)
        }
    }
}
