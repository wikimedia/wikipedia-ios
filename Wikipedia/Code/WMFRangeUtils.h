static inline BOOL WMFRangeIsNotFoundOrEmpty(NSRange const range) {
    return range.location == NSNotFound || range.length == 0;
}

static inline NSRange WMFRangeMakeNotFound() {
    return NSMakeRange(NSNotFound, 0);
}

static inline NSUInteger WMFRangeGetMaxIndex(NSRange const range) {
    return range.location != NSNotFound ? range.location + range.length
                                        : NSNotFound;
}
