import Foundation

public final class DirectoryExploreStreamHandler: StreamHandling {
    enum Error: Swift.Error {
        case inputStreamFinishedBeforeCompleteHeader
        case notSupportedProtocol
        case failToOpenFile
    }

    public struct Request {
        let headerInfo: RequestHeaderInfo
        let body: Data
    }

    public var inputBufferSize: Int = 1024
    private var outputBufferSize: Int = 1024 * 1024

    private let fileProvider: (Request) async throws -> URL

    public init(fileProvider: @escaping (Request) async throws -> URL) {
        self.fileProvider = fileProvider
    }

    public func handle(input: AsyncThrowingDataStream, outputWriter: AsyncOutputWriter) {
        Task {
            do {
                let request = try await parseRequest(input: input)
                let (fileHandle, fileMimeType, fileSize) = try await fileAttributes(for: request)
                let responseHeader = try await getResponseHeader(mimeType: fileMimeType, fileSize: fileSize)
                try await stream(headerData: responseHeader, file: fileHandle, to: outputWriter)
                outputWriter.finish()
            } catch {
                await respond(with: error, writer: outputWriter)
            }
        }
    }

    private func parseRequest(input: AsyncThrowingDataStream) async throws -> Request {
        var headerParser = HttpHeaderParser()
        var bodyData = Data()
        for try await data in input {
            guard case .ready = headerParser.state else {
                try headerParser.parse(streamData: data, extraDataBuffer: &bodyData)
                continue
            }
            bodyData.append(contentsOf: data)
        }
        guard case .ready(let headerInfo) = headerParser.state else {
            throw Error.inputStreamFinishedBeforeCompleteHeader
        }
        guard headerInfo.protocol.starts(with: "HTTP") else {
            throw Error.notSupportedProtocol
        }
        return Request(headerInfo: headerInfo, body: bodyData)
    }

    private func stream(headerData: Data, file: FileHandle, to writer: AsyncOutputWriter) async throws {
        let fileData = try file.read(upToCount: outputBufferSize - headerData.count) ?? Data()
        try await writer.write(data: [UInt8](headerData + fileData))

        while let data = try file.read(upToCount: outputBufferSize) {
            try await writer.write(data: [UInt8](data))
        }
    }

    private func fileAttributes(for request: Request) async throws -> (FileHandle, mimeType: String, size: Int) {
        let fileURL = try await fileProvider(request)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let size = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        else {
            throw HttpError(status: .notFound)
        }

        guard let handle = FileHandle(forReadingAtPath: fileURL.path) else {
            throw Error.failToOpenFile
        }
        return (handle, fileURL.mimeType, size)
    }

    private func getResponseHeader(mimeType: String, fileSize: Int) async throws -> Data {
        let response = """
        HTTP/1.1 \(HTTPStatus.ok.code) \(HTTPStatus.ok.message)
        \(HttpHeaderKey.server): Swift Server
        \(HttpHeaderKey.connection): close
        \(HttpHeaderKey.contentType): \(mimeType)
        \(HttpHeaderKey.contentLength): \(fileSize)\r\n\r\n
        """
        return response.data(using: .utf8)!
    }

    private func respond(with error: Swift.Error, writer: AsyncOutputWriter) async {
        let httpError: HttpError
        if let error = error as? HttpError {
            httpError = error
        } else {
            httpError = HttpError(status: .internalServerError, message: error.localizedDescription)
        }
        let response = """
        HTTP/1.1 \(httpError.status.code) \(httpError.status.message)
        \(HttpHeaderKey.server): Swift Server
        \(HttpHeaderKey.connection): close
        \(HttpHeaderKey.date): \(Date())
        \(HttpHeaderKey.contentType): text/html;charset=utf-8
        \(HttpHeaderKey.contentLength): 0\r\n\r\n
        """
        let data = Data(response.utf8)
        do {
            try await writer.write(data: [UInt8](data))
        } catch {
            assertionFailure("Failed to respond with error")
        }
        writer.finish()
    }
}
