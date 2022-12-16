import Foundation

extension OutputStream {
    public enum Error: LocalizedError {
        case unknownOutputError
        case closedUnexpectedly
    }

    private final class Writer: AsyncOutputWriter, @unchecked Sendable {
        private let outputStream: OutputStream

        private var streamDelegate: StreamDelegateHandler<OutputStream>?
        private var finishCalled = false
        private var currentWriteTask: (data: [UInt8], completion: (Result<Void, Swift.Error>) -> Void)?
        private var taskInProgress = false

        init(outputStream: OutputStream) {
            self.outputStream = outputStream
        }

        func write(data: [UInt8]) async throws {
            if taskInProgress {
                assertionFailure("nope")
            }
            currentWriteTask = nil
            taskInProgress = true
            print("Write started \(Date().timeIntervalSince1970)")
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                currentWriteTask = (data, { result in
                    continuation.resume(with: result)
                    print("Write finished \(Date().timeIntervalSince1970)")
                    self?.taskInProgress = false
                })
                openIfNeeded()
            }
        }

        func finish() {
            print("OutputStream finish")
            // queue.sync {
            guard !finishCalled else { return }
            finishCalled = true
            streamDelegate = nil
            currentWriteTask = nil
            outputStream.remove(from: .main, forMode: .common)
            outputStream.close()
            // }
        }

        private func triggerNextWrite() {
            guard let task = currentWriteTask else { return }
            currentWriteTask = nil

            Task {
                let result = outputStream.write(task.data, maxLength: task.data.count)

                if result >= 0 {
                    let restOfData = Array(task.data.dropFirst(result))
                    guard !restOfData.isEmpty else {
                        task.completion(.success(()))
                        return
                    }
                    currentWriteTask = (restOfData, task.completion)
                } else if result < 0 {
                    task.completion(.failure(outputStream.streamError ?? Error.unknownOutputError))
                }
            }
        }

        private func openIfNeeded() {
            guard streamDelegate == nil else {
                triggerNextWrite()
                return
            }
            streamDelegate = StreamDelegateHandler<OutputStream>()
            streamDelegate?.eventUpdateClosure = { [weak self] stream, event in
                // self?.queue.async { [weak self] in
                guard let self = self else { return }
                switch event {
                case .openCompleted:
                    self.triggerNextWrite()

                case .hasSpaceAvailable:
                    self.triggerNextWrite()

                case .errorOccurred:
                    self.currentWriteTask?.completion(.failure(stream.streamError ?? Error.unknownOutputError))
                    self.currentWriteTask = nil

                case .endEncountered:
                    guard !self.finishCalled else { return }
                    self.currentWriteTask?.completion(.failure(Error.closedUnexpectedly))
                    self.currentWriteTask = nil

                default:
                    break
                }
                // }
            }

            outputStream.delegate = streamDelegate
            outputStream.schedule(in: .main, forMode: .common)
            outputStream.open()
        }
    }

    var writer: AsyncOutputWriter {
        Writer(outputStream: self)
    }
}
