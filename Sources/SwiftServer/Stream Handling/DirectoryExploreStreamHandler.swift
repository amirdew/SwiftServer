import Foundation

public final class DirectoryExploreStreamHandler: StreamHandling {
    enum Error: Swift.Error {
        case inputStreamFinishedBeforeCompleteHeader
    }

    struct Request {
        let headerInfo: RequestHeaderInfo
        let body: Data
    }

    public static var inputBufferSize: Int = 240

    public init() {}

    public func handle(input: AsyncThrowingDataStream, outputWriter: AsyncOutputWriter) {
        Task {
            do {
                let request = try await parseRequest(input: input)
                print(request)
                try await outputWriter.write(data: [UInt8](getResponse(request: request)))
                outputWriter.finish()
            } catch {
                print(error)
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

    private func getResponse(request: Request) -> Data {
        let body = """
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
                "http://www.w3.org/TR/html4/strict.dtd">
        <html>
            <body>
                <h1>Response</h1>
                <p>\(request)</p>
            </body>
        </html>
        """

        let respond = """
        HTTP/1.0 200 OK
        Server: Swift Server
        Connection: close
        Content-Type: text/html;charset=utf-8
        Content-Length: \(body.count)

        \(body)
        """
        return respond.data(using: .utf8)!
    }
}
