import Foundation
import UniformTypeIdentifiers

public extension URL {
    var mimeType: String {
        if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }
}
