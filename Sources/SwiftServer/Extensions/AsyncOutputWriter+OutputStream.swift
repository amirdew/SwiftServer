import Foundation

extension OutputStream {
    public enum Error: LocalizedError {
        case unknownOutputError
        case closedUnexpectedly
    }

    private final class Writer: AsyncOutputWriter, @unchecked Sendable {
        private let outputStream: OutputStream

        private let queue = DispatchQueue(label: "OutputStream.Writer.queue", qos: .userInitiated)
        private var streamDelegate: StreamDelegateHandler<OutputStream>?
        private var finishCalled = false
        private var nextWriteTask: (data: [UInt8], continuation: CheckedContinuation<Void, Swift.Error>)?

        init(outputStream: OutputStream) {
            self.outputStream = outputStream
        }

        func write(data: [UInt8]) async throws {
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                queue.sync { [weak self] in
                    nextWriteTask = (data, continuation)
                    self?.openIfNeeded()
                    self?.triggerNextWrite()
                }
            }
        }

        func finish() {
            queue.sync {
                guard !finishCalled else { return }
                finishCalled = true
                streamDelegate = nil
                nextWriteTask = nil
                outputStream.remove(from: .current, forMode: .common)
                outputStream.close()
            }
        }

        private func triggerNextWrite() {
            guard let task = nextWriteTask else { return }
            nextWriteTask = nil

            let result = outputStream.write(task.data, maxLength: task.data.count)

            if result >= 0 {
                let restOfData = Array(task.data.dropFirst(result))
                guard !restOfData.isEmpty else {
                    task.continuation.resume()
                    triggerNextWrite()
                    return
                }
                nextWriteTask = (restOfData, task.continuation)
                triggerNextWrite()
            } else if result < 0 {
                task.continuation.resume(throwing: outputStream.streamError ?? Error.unknownOutputError)
            }
        }

        private func openIfNeeded() {
            guard streamDelegate == nil else { return }
            streamDelegate = StreamDelegateHandler<OutputStream>()
            streamDelegate?.eventUpdateClosure = { [weak self] stream, event in
                self?.queue.async { [weak self] in
                    guard let self = self else { return }
                    switch event {
                    case Stream.Event.hasSpaceAvailable:
                        self.triggerNextWrite()

                    case Stream.Event.errorOccurred:
                        self.nextWriteTask?.continuation.resume(throwing: stream.streamError ?? Error.unknownOutputError)
                        self.nextWriteTask = nil

                    case Stream.Event.endEncountered:
                        guard !self.finishCalled else { return }
                        self.nextWriteTask?.continuation.resume(throwing: Error.closedUnexpectedly)
                        self.nextWriteTask = nil

                    default:
                        break
                    }
                }
            }

            outputStream.delegate = streamDelegate
            outputStream.schedule(in: .current, forMode: .common)
            outputStream.open()
        }
    }

    var writer: AsyncOutputWriter {
        Writer(outputStream: self)
    }
}
