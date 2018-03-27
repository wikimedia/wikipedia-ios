public enum ReadingListAlertType {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case genericNotSynced
    case downloading
}

extension ReadingListAlertType: Equatable {
    public static func ==(lhs: ReadingListAlertType, rhs: ReadingListAlertType) -> Bool {
        switch (lhs, rhs) {
        case  (.listLimitExceeded, .listLimitExceeded),
              (.entryLimitExceeded, .entryLimitExceeded),
              (.genericNotSynced, .genericNotSynced),
              (.downloading, .downloading):
            return true
        default:
            return false
        }
    }
}
