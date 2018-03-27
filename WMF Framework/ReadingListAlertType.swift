public enum ReadingListAlertType {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case genericNotSynced
    case downloading
}

extension ReadingListAlertType: Equatable {
    public static func ==(lhs: ReadingListAlertType, rhs: ReadingListAlertType) -> Bool {
        switch (lhs, rhs) {
        case let (.listLimitExceeded(a), .listLimitExceeded(b)),
             let (.entryLimitExceeded(a), .entryLimitExceeded(b)):
            return a == b
        case (.genericNotSynced, .genericNotSynced),
             (.downloading, .downloading):
            return true
        default:
            return false
        }
    }
}
