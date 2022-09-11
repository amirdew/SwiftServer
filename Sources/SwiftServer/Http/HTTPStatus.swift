public struct HTTPStatus {
    enum Error: Swift.Error {
        case invalidCode
    }

    public let code: UInt16
    public var customMessage: String?
    public var message: String {
        return HTTPStatus.messages[code] ?? customMessage ?? "Unknown"
    }

    public init(code: UInt16, customMessage: String? = nil) throws {
        guard HTTPStatus.isValid(code: code) else {
            throw Error.invalidCode
        }

        self.code = code
        self.customMessage = customMessage
    }

    static func isValid(code: UInt16) -> Bool {
        return (100 ... 599).contains(code)
    }
}

public extension HTTPStatus {
    enum Family: String {
        case informational
        case successful
        case redirection
        case clientError
        case serverError

        var range: ClosedRange<UInt16> {
            switch self {
            case .informational: return 100 ... 199
            case .successful: return 200 ... 299
            case .redirection: return 300 ... 399
            case .clientError: return 400 ... 499
            case .serverError: return 500 ... 599
            }
        }
    }

    var family: Family {
        switch code {
        case Family.informational.range:
            return .informational
        case Family.successful.range:
            return .successful
        case Family.redirection.range:
            return .redirection
        case Family.clientError.range:
            return .clientError
        case Family.serverError.range:
            return .serverError
        default:
            return .serverError
        }
    }

    var isInformational: Bool { return family == .informational }
    var isSuccessful: Bool { return family == .successful }
    var isRedirection: Bool { return family == .redirection }
    var isClientError: Bool { return family == .clientError }
    var isServerError: Bool { return family == .serverError }
}

extension HTTPStatus: ExpressibleByIntegerLiteral {
    public init(integerLiteral: UInt16) {
        do {
            try self.init(code: integerLiteral)
        } catch {
            assertionFailure("Failed to initialize HTTPStatus from \(integerLiteral), \(error)")
            self = .ok
        }
    }
}

extension HTTPStatus: CustomStringConvertible {
    public var description: String {
        return "\(code) \(message)"
    }
}

extension HTTPStatus: Equatable {
    public static func == (left: Self, right: Self) -> Bool {
        return left.code == right.code
    }
}

extension HTTPStatus: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension HTTPStatus {
    static var messages: [UInt16: String] = [
        100: "Continue",
        101: "Switching Protocols",
        102: "Processing",

        200: "OK",
        201: "Created",
        202: "Accepted",
        203: "Non-Authoritative Information",
        204: "No Content",
        205: "Reset Content",
        206: "Partial Content",
        207: "Multi-Status",
        208: "Already Reported",
        226: "IM Used",

        300: "Multiple Choices",
        301: "Moved Permanently",
        302: "Found",
        303: "See Other",
        304: "Not Modified",
        305: "Use Proxy",
        306: "Switch Proxy",
        307: "Temporary Redirect",
        308: "Permanent Redirect",

        400: "Bad Request",
        401: "Unauthorized",
        402: "Payment Required",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        406: "Not Acceptable",
        407: "Proxy Authentication Required",
        408: "Request Timeout",
        409: "Conflict",
        410: "Gone",
        411: "Length Required",
        412: "Precondition Failed",
        413: "Payload Too Large",
        414: "URI Too Long",
        415: "Unsupported Media Type",
        416: "Range Not Satisfiable",
        417: "Expectation Failed",
        418: "Im A Teapot",
        419: "Authentication Timeout",
        421: "Misdirected Request",
        422: "Unprocessable Entity",
        423: "Locked",
        424: "Failed Dependency",
        426: "Upgrade Required",
        428: "Precondition Required",
        429: "Too Many Requests",
        431: "Request Header Fields Too Large",
        440: "Login Timeout",
        444: "No Response",
        449: "Retry With",
        451: "Unavailable For Legal Reasons",
        494: "Request Header Too Large",
        495: "Cert Error",
        496: "No Cert",
        497: "HTTP To HTTPS",
        498: "Token Expired",
        499: "Client Closed Request",

        500: "Internal Server Error",
        501: "Not Implemented",
        502: "Bad Gateway",
        503: "Service Unavailable",
        504: "Gateway Timeout",
        505: "HTTP Version Not Supported",
        506: "Variant Also Negotiates",
        507: "Insufficient Storage",
        508: "Loop Detected",
        509: "Bandwidth Limit Exceeded",
        510: "Not Extended",
        511: "Network Authentication Required",
        599: "Network Timeout Error"
    ]
}

public extension HTTPStatus {
    static let `continue`: HTTPStatus = 100
    static let switchingProtocols: HTTPStatus = 101
    static let processing: HTTPStatus = 102

    static let ok: HTTPStatus = 200
    static let created: HTTPStatus = 201
    static let accepted: HTTPStatus = 202
    static let nonAuthoritativeInformation: HTTPStatus = 203
    static let noContent: HTTPStatus = 204
    static let resetContent: HTTPStatus = 205
    static let partialContent: HTTPStatus = 206
    static let multiStatus: HTTPStatus = 207
    static let alreadyReported: HTTPStatus = 208
    static let imUsed: HTTPStatus = 226

    static let multipleChoices: HTTPStatus = 300
    static let movedPermanently: HTTPStatus = 301
    static let found: HTTPStatus = 302
    static let seeOther: HTTPStatus = 303
    static let notModified: HTTPStatus = 304
    static let useProxy: HTTPStatus = 305
    static let switchProxy: HTTPStatus = 306
    static let temporaryRedirect: HTTPStatus = 307
    static let permanentRedirect: HTTPStatus = 308

    static let badRequest: HTTPStatus = 400
    static let unauthorized: HTTPStatus = 401
    static let paymentRequired: HTTPStatus = 402
    static let forbidden: HTTPStatus = 403
    static let notFound: HTTPStatus = 404
    static let methodNotAllowed: HTTPStatus = 405
    static let notAcceptable: HTTPStatus = 406
    static let proxyAuthenticationRequired: HTTPStatus = 407
    static let requestTimeout: HTTPStatus = 408
    static let conflict: HTTPStatus = 409
    static let gone: HTTPStatus = 410
    static let lengthRequired: HTTPStatus = 411
    static let preconditionFailed: HTTPStatus = 412
    static let payloadTooLarge: HTTPStatus = 413
    static let uriTooLong: HTTPStatus = 414
    static let unsupportedMediaType: HTTPStatus = 415
    static let rangeNotSatisfiable: HTTPStatus = 416
    static let expectationFailed: HTTPStatus = 417
    static let imATeapot: HTTPStatus = 418
    static let authenticationTimeout: HTTPStatus = 419
    static let misdirectedRequest: HTTPStatus = 421
    static let unprocessableEntity: HTTPStatus = 422
    static let locked: HTTPStatus = 423
    static let failedDependency: HTTPStatus = 424
    static let upgradeRequired: HTTPStatus = 426
    static let preconditionRequired: HTTPStatus = 428
    static let tooManyRequests: HTTPStatus = 429
    static let requestHeaderFieldsTooLarge: HTTPStatus = 431
    static let loginTimeout: HTTPStatus = 440
    static let noResponse: HTTPStatus = 444
    static let retryWith: HTTPStatus = 449
    static let unavailableForLegalReasons: HTTPStatus = 451
    static let requestHeaderTooLarge: HTTPStatus = 494
    static let certError: HTTPStatus = 495
    static let noCert: HTTPStatus = 496
    static let httpToHTTPS: HTTPStatus = 497
    static let tokenExpired: HTTPStatus = 498
    static let clientClosedRequest: HTTPStatus = 499

    static let internalServerError: HTTPStatus = 500
    static let notImplemented: HTTPStatus = 501
    static let badGateway: HTTPStatus = 502
    static let serviceUnavailable: HTTPStatus = 503
    static let gatewayTimeout: HTTPStatus = 504
    static let httpVersionNotSupported: HTTPStatus = 505
    static let variantAlsoNegotiates: HTTPStatus = 506
    static let insufficientStorage: HTTPStatus = 507
    static let loopDetected: HTTPStatus = 508
    static let bandwidthLimitExceeded: HTTPStatus = 509
    static let notExtended: HTTPStatus = 510
    static let networkAuthenticationRequired: HTTPStatus = 511
    static let networkTimeoutError: HTTPStatus = 599
}
