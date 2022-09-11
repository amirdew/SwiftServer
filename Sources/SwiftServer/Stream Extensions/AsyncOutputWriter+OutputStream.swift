import Foundation

extension OutputStream {
    public enum Error: LocalizedError {
        case unknownOutputError
        case closedUnexpectedly
    }

    private final class Writer: AsyncOutputWriter, @unchecked Sendable {
        private let outputStream: OutputStream

        private let queue = DispatchQueue(label: "OutputStream.Writer.queue", qos: .userInitiated)
        private var opened = false
        private var finishCalled = false
        private var currentContinuation: CheckedContinuation<Void, Swift.Error>?
        private var spaceAvailabilitySemaphore: DispatchSemaphore?

        init(outputStream: OutputStream) {
            self.outputStream = outputStream
        }

        func write(data: [UInt8]) async throws {
            return try await withCheckedThrowingContinuation { continuation in
                queue.async { [weak self] in
                    guard let self = self else { return }
                    self.openIfNeeded()
                    self.currentContinuation = continuation
                    var dataToWrite = data
                    while !dataToWrite.isEmpty {
                        self.spaceAvailabilitySemaphore?.wait()
                        let result = self.outputStream.write(dataToWrite, maxLength: dataToWrite.count)
                        if result >= 0 {
                            dataToWrite = Array(dataToWrite.dropFirst(result))
                            self.spaceAvailabilitySemaphore = .init(value: 0)
                        } else if result < 0 {
                            continuation.resume(throwing: self.outputStream.streamError ?? Error.unknownOutputError)
                            self.currentContinuation = nil
                            break
                        }
                    }

                    continuation.resume()
                    self.currentContinuation = nil
                    self.spaceAvailabilitySemaphore = nil
                }
            }
        }

        func finish() {
            queue.sync {
                guard !finishCalled else { return }
                finishCalled = true
                outputStream.close()
                outputStream.remove(from: .current, forMode: .common)
            }
        }

        private func openIfNeeded() {
            guard !opened else { return }
            opened = true
            let delegate = StreamDelegateHandler<OutputStream>()
            delegate.eventUpdateClosure = { [weak self] stream, event in
                guard let self = self else { return }
                switch event {
                case Stream.Event.hasSpaceAvailable:
                    self.spaceAvailabilitySemaphore?.signal()

                case Stream.Event.errorOccurred:
                    self.currentContinuation?.resume(throwing: stream.streamError ?? Error.unknownOutputError)
                    self.currentContinuation = nil

                case Stream.Event.endEncountered:
                    guard !self.finishCalled else { return }
                    self.currentContinuation?.resume(throwing: Error.closedUnexpectedly)
                    self.currentContinuation = nil

                default:
                    break
                }
            }

            outputStream.delegate = delegate
            outputStream.schedule(in: .current, forMode: .common)
            outputStream.open()
        }
    }

    var writer: AsyncOutputWriter {
        Writer(outputStream: self)
    }
}
