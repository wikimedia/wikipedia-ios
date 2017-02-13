#import "WMFArticle+Extensions.h"

@implementation WMFArticle (Extensions)

- (nullable NSURL *)URL {
    NSString *key = self.key;
    if (!key) {
        return nil;
    }
    return [NSURL URLWithString:key];
}

- (nullable NSURL *)thumbnailURL {
    NSString *thumbnailURLString = self.thumbnailURLString;
    if (!thumbnailURLString) {
        return nil;
    }
    return [NSURL URLWithString:thumbnailURLString];
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL {
    self.thumbnailURLString = thumbnailURL.absoluteString;
}

- (NSArray<NSNumber *> *)pageViewsSortedByDate {
    return self.pageViews.wmf_pageViewsSortedByDate;
}

- (void)updateViewedDateWithoutTime {
    NSDate *viewedDate = self.viewedDate;
    if (viewedDate) {
        NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:viewedDate];
        self.viewedDateWithoutTime = [calendar dateFromComponents:components];
    } else {
        self.viewedDateWithoutTime = nil;
    }
}

@end
