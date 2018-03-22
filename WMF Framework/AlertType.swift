public enum AlertType {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case genericNotSynced
    case downloading
}

extension AlertType: Equatable {
    public static func ==(lhs: AlertType, rhs: AlertType) -> Bool {
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
