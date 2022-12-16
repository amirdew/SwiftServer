import Foundation

extension AsyncThrowingDataStream {
    enum Error: LocalizedError {
        case unknownInputError
    }

    init(inputStream: InputStream, bufferSize: Int) {
        self = AsyncThrowingDataStream { continuation in
            var isReading = false
            let read: (InputStream) async -> Void = { stream in
                guard !isReading else { return }
                isReading = true
                await Self.read(from: stream, bufferSize: bufferSize, continuation: continuation)
                isReading = false
            }
            let delegate = StreamDelegateHandler<InputStream>()
            delegate.eventUpdateClosure = { stream, event in
                switch event {
                case Stream.Event.openCompleted:
                    Task { await read(stream) }

                case Stream.Event.hasBytesAvailable:
                    Task { await read(stream) }

                case Stream.Event.errorOccurred:
                    continuation.finish(throwing: stream.streamError ?? Error.unknownInputError)

                case Stream.Event.endEncountered:
                    continuation.finish()

                default:
                    break
                }
            }

            continuation.onTermination = { termination in
                delegate.eventUpdateClosure = nil
                inputStream.close()
                inputStream.remove(from: .main, forMode: .common)
            }
            inputStream.delegate = delegate
            inputStream.schedule(in: .main, forMode: .common)
            inputStream.open()
        }
    }

    private static func read(from inputStream: InputStream, bufferSize: Int, continuation: Continuation) async {
        var buffer: [UInt8] = Array(repeating: 0, count: bufferSize)
        var result = 0
        repeat {
            result = inputStream.read(&buffer, maxLength: bufferSize)
            continuation.yield(buffer)
            buffer = Array(repeating: 0, count: bufferSize)
        } while result > 0 && inputStream.hasBytesAvailable
        continuation.finish()
    }
}
