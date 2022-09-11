import Foundation

extension AsyncThrowingDataStream {
    enum Error: LocalizedError {
        case unknownInputError
    }

    init<InputType: InputStream>(inputStream: InputType, bufferSize: Int) {
        self = AsyncThrowingDataStream { continuation in
            let queue = DispatchQueue(label: "AsyncThrowingDataStream.read")
            let read: (InputType) -> Void = { stream in
                var buffer: [UInt8] = Array(repeating: 0, count: bufferSize)
                while stream.read(&buffer, maxLength: bufferSize) > 0 {
                    continuation.yield(buffer)
                    buffer = Array(repeating: 0, count: bufferSize)
                    if !stream.hasBytesAvailable {
                        break
                    }
                }
                continuation.finish()
            }
            let delegate = StreamDelegateHandler<InputType>()
            delegate.eventUpdateClosure = { [weak queue] stream, event in
                switch event {
                case Stream.Event.hasBytesAvailable:
                    queue?.async {
                        read(stream)
                    }

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
            }
            inputStream.delegate = delegate
            inputStream.schedule(in: .current, forMode: .common)
            inputStream.open()
            queue.async {
                read(inputStream)
            }
        }
    }
}
