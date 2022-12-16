import Foundation

public final class WebServer {
    enum Error: LocalizedError {
        case alreadyRunning
    }

    private var socket: Socket?
    private var connectionTask: Task<Void, Never>?
    private var streamHandler: () -> StreamHandling

    public init(streamHandler: @escaping () -> StreamHandling) {
        self.streamHandler = streamHandler
    }

    public func start(address: InternetAddress = .loopback, port: UInt16) throws {
        guard socket == nil else {
            throw Error.alreadyRunning
        }
        // check socket status and restart if needed.
        // 
        socket = Socket(address: address, port: port)
        try socket?.start()
        guard let connectionStream = socket?.connectionStream else { return }

        connectionTask = Task.detached(priority: .userInitiated) {
            for await connection in connectionStream {
                await self.serve(input: connection.input, output: connection.output)
            }
        }
    }

    public func stop() {
        connectionTask?.cancel()
        socket?.stop()
        socket = nil
        connectionTask = nil
    }

    private var handlers: [StreamHandling] = []
    
    private func serve(input: InputStream, output: OutputStream) async {
        let handler = streamHandler()
        let inputStream = AsyncThrowingStream(inputStream: input, bufferSize: handler.inputBufferSize)
        await handler.handle(input: inputStream, outputWriter: output.writer)
    }

    deinit {
        stop()
    }
}
