import Foundation

struct ChatMessage {
    var text: String
    var type: MessageStatus
    var status: MessageType
    //var isUnread: Bool
}

enum MessageStatus {
    case queued, sent, failed
}

enum MessageType {
    case sent, received
}
