import Foundation

struct HttpHeaderParser {
    enum State {
        case moreDataNeeded
        case ready(RequestHeaderInfo)
    }

    private enum Constants {
        static let headerBodySeparator = Data("\r\n\r\n".utf8)
    }

    var maxHeaderSize: Int = 8 * 1024

    private(set) var state: State = .moreDataNeeded
    private var parsedData = [UInt8]()

    mutating func parse(streamData: [UInt8], extraDataBuffer: inout Data) throws {
        guard case .moreDataNeeded = state else { return }

        guard parsedData.count + streamData.count < maxHeaderSize else {
            throw HttpError(status: .requestHeaderTooLarge)
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
