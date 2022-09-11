import Foundation

final class StreamDelegateHandler<StreamType: Stream>: NSObject, StreamDelegate {
    typealias EventUpdateClosure = (StreamType, Stream.Event) -> Void
    var eventUpdateClosure: EventUpdateClosure?

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let stream = aStream as? StreamType else { return }
        eventUpdateClosure?(stream, eventCode)
    }
}
