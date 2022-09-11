import Foundation

public struct RequestHeaderInfo {
    private enum Constants {
        static let separator = "\r\n"
        static let requestLineSeparator = " "
        static let headerKeyValueSeparator = ": "
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
            let headerLineComponents = headerLine.components(separatedBy: Constants.headerKeyValueSeparator)
            guard headerLineComponents.count == 2 else { return }
            headers[.init(rawValue: headerLineComponents[0])] = headerLineComponents[1]
        }
        self.headers = headers
    }
}
