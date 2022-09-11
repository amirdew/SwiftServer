import Foundation

public struct HttpError: Error {
    let status: HTTPStatus
    var message: String?
}
