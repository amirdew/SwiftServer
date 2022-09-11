import Foundation

public typealias AsyncThrowingDataStream = AsyncThrowingStream<[UInt8], Error>

public protocol AsyncOutputWriter {
    func write(data: [UInt8]) async throws
    func finish()
}

public protocol StreamHandling {
    static var inputBufferSize: Int { get }
    func handle(input: AsyncThrowingDataStream, outputWriter: AsyncOutputWriter)
}
