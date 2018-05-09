public enum ReadingListAlertType {
    case listLimitExceeded(limit: Int)
    case entryLimitExceeded(limit: Int)
    case genericNotSynced
    case downloading
    case articleError(_: ArticleError)
}

extension ReadingListAlertType: Equatable {
    public static func ==(lhs: ReadingListAlertType, rhs: ReadingListAlertType) -> Bool {
        switch (lhs, rhs) {
        case  (.listLimitExceeded, .listLimitExceeded),
              (.entryLimitExceeded, .entryLimitExceeded),
              (.genericNotSynced, .genericNotSynced),
              (.downloading, .downloading),
              (.articleError, .articleError):
            return true
        default:
            return false
        }
    }
}
