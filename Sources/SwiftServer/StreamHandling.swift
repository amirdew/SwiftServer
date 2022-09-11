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

public final class StreamHandler: StreamHandling {
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

public struct HttpMethod: RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let get: HttpMethod = "GET"
    static let post: HttpMethod = "POST"
    static let put: HttpMethod = "PUT"
    static let delete: HttpMethod = "DELETE"
}

extension HttpMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

public struct HttpHeaderKey: RawRepresentable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }

    static let contentType: HttpMethod = "content-type"
}

extension HttpHeaderKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

struct RequestHeaderInfo {
    private enum Constants {
        static let separator = "\r\n"
        static let requestLineSeparator = " "
    }

    enum Error: Swift.Error {
        case notValidRequestLine
    }

    let method: HttpMethod
    let path: String
    let `protocol`: String
    var headers: [HttpHeaderKey: String]

    init(data: [UInt8]) throws {
        let header = String(decoding: data, as: UTF8.self)
        var headerLines = header.components(separatedBy: Constants.separator)
        guard let requestLine = headerLines.first else {
            throw Error.notValidRequestLine
        }
        let requestComponents = requestLine.components(separatedBy: Constants.requestLineSeparator)
        guard requestComponents.count == 3 else {
            throw Error.notValidRequestLine
        }
        method = HttpMethod(rawValue: requestComponents[0])
        path = requestComponents[1]
        self.protocol = requestComponents[2]

        headerLines = Array(headerLines.dropFirst())
        var headers: [HttpHeaderKey: String] = [:]
        headerLines.forEach { headerLine in
            let headerLineComponents = headerLine.components(separatedBy: Constants.separator)
            guard headerLineComponents.count == 2 else { return }
            headers[.init(rawValue: headerLineComponents[0])] = headerLineComponents[1]
        }
        self.headers = headers
    }
}

struct HttpHeaderParser {
    enum State {
        case moreDataNeeded
        case ready(RequestHeaderInfo)
    }

    private enum Constants {
        static let headerBodySeparator = Data("\r\n\r\n".utf8)
    }

    enum Error: Swift.Error {
        case maxSizeReached
    }

    var maxHeaderSize: Int = 8 * 1024

    private(set) var state: State = .moreDataNeeded
    private var parsedData = [UInt8]()

    mutating func parse(streamData: [UInt8], extraDataBuffer: inout Data) throws {
        guard case .moreDataNeeded = state else { return }

        guard parsedData.count + streamData.count < maxHeaderSize else {
            throw Error.maxSizeReached
        }
        parsedData.append(contentsOf: streamData)
        if let range = parsedData.firstRange(of: Constants.headerBodySeparator) {
            let headerData = Array(parsedData[0 ..< range.lowerBound])
            let restOfData = Array(parsedData[range.upperBound...])
            extraDataBuffer.append(contentsOf: restOfData)
            let headerInfo = try RequestHeaderInfo(data: headerData)
            state = .ready(headerInfo)
        }
    }
}
