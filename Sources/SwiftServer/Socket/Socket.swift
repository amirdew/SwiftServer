import Foundation

/// wrapper around `CFSocket`
public class Socket {
    enum Error: LocalizedError {
        case failedToStart(CFSocketError)

        var errorDescription: String? {
            switch self {
            case .failedToStart(let cfSocketError):
                return "Failed to start \(cfSocketError)"
            }
        }
    }

    struct Connection {
        let input: InputStream
        let output: OutputStream
    }

    typealias ConnectionStream = AsyncStream<Connection>

    let address: SocketAddress
    private(set) var connectionStream: ConnectionStream!
    private var connectionStreamContinuation: ConnectionStream.Continuation?
    private var cfSocket: CFSocket!

    private let acceptCallBack: CFSocketCallBack = { _, _, _, data, info in
        guard let data = data, let info = info
        else { return }

        let nativeHandle = data.load(as: CFSocketNativeHandle.self)
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocket(nil, nativeHandle, &readStream, &writeStream)

        guard let readStream = readStream, let writeStream = writeStream else { return }

        let inputStream = readStream.takeUnretainedValue() as InputStream
        let outputStream = writeStream.takeUnretainedValue() as OutputStream
        CFReadStreamSetProperty(inputStream, CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
        CFWriteStreamSetProperty(outputStream, CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)

        let `self` = Unmanaged<Socket>.fromOpaque(info).takeUnretainedValue()
        self.connectionStreamContinuation?.yield(.init(input: inputStream, output: outputStream))
    }

    public init(address: InternetAddress, port: UInt16) {
        self.address = SocketAddress(address: address, port: port)
        connectionStream = .init { [weak self] continuation in
            self?.connectionStreamContinuation = continuation
        }
        let protocolFamily: Int32
        switch address.ip {
        case .v6:
            protocolFamily = PF_INET6
        case .v4:
            protocolFamily = PF_INET
        }
        var context = CFSocketContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()
        cfSocket = CFSocketCreate(
            nil,
            protocolFamily,
            SOCK_STREAM,
            IPPROTO_TCP,
            CFSocketCallBackType.acceptCallBack.rawValue,
            acceptCallBack,
            &context
        )
    }

    public func start() throws {
        let error = CFSocketSetAddress(cfSocket, address.data as CFData)
        guard error == .success else {
            throw Error.failedToStart(error)
        }
        let priorityIndex = 0
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, cfSocket, priorityIndex)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
    }

    public func stop() {
        CFSocketInvalidate(cfSocket)
    }
}
