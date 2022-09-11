import Foundation

struct HttpError: Error {
    let status: HTTPStatus
    var message: String?
}
