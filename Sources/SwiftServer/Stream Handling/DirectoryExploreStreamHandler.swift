import Foundation

public final class DirectoryExploreStreamHandler: StreamHandling {
    enum Error: Swift.Error {
        case inputStreamFinishedBeforeCompleteHeader
        case notSupportedProtocol
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
                guard request.headerInfo.protocol.starts(with: "HTTP") else {
                    throw Error.notSupportedProtocol
                }
                try await outputWriter.write(data: [UInt8](getResponse(request: request)))
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
        return Request(headerInfo: headerInfo, body: bodyData)
    }

    private func getResponse(request: Request) async throws -> Data {
        let fileURL = try await fileProvider(request)
        guard FileManager.default.fileExists(atPath: fileURL.pathExtension) else {
            throw HttpError(status: .notFound)
        }

        let body = """

        """

        let contentType = ""
        let response = """
        HTTP/1.1 \(HTTPStatus.ok.code) \(HTTPStatus.ok.message)
        \(HttpHeaderKey.server): Swift Server
        \(HttpHeaderKey.connection): close
        \(HttpHeaderKey.contentType): \(contentType)
        \(HttpHeaderKey.contentLength): \(body.count)

        \(body)
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
