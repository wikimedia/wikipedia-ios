#import "WMFContentGroup.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup ()

@property (nonatomic, strong, readwrite) NSDate *date;

@end

@implementation WMFContentGroup

+ (NSString *)kind {
    return NSStringFromClass([self class]);
}

- (instancetype)init {
    return [self initWithDate:[NSDate date]];
}

- (instancetype)initWithDate:(NSDate *)date {
    NSParameterAssert(date);
    self = [super init];
    if (self) {
        self.date = date;
    }
    return self;
}

- (WMFContentType)contentType {
    return WMFContentTypeURL;
}

- (NSInteger)dailySortPriority {
    return 0;
}

- (NSComparisonResult)compare:(WMFContentGroup *)contentGroup {
    NSParameterAssert([contentGroup isKindOfClass:[WMFContentGroup class]]);
    if ([self isKindOfClass:[WMFAnnouncementContentGroup class]]) {
        // announcements always go above everything else, regardless of date
        return NSOrderedAscending;
    } else if ([contentGroup isKindOfClass:[WMFAnnouncementContentGroup class]]) {
        // corollary of above
        return NSOrderedDescending;
    } else if ([self isKindOfClass:[WMFContinueReadingContentGroup class]]) {
        // continue reading always goes above everything else but announcements, regardless of date
        return NSOrderedAscending;
    } else if ([contentGroup isKindOfClass:[WMFContinueReadingContentGroup class]]) {
        // corollary of above, everything else always goes below continue reading, regardless of date
        return NSOrderedDescending;
    } else if (![self isKindOfClass:[WMFRelatedPagesContentGroup class]] && ![contentGroup isKindOfClass:[WMFRelatedPagesContentGroup class]] && [self.date isEqualToDateIgnoringTime:contentGroup.date]) {
        // explicit ordering for non-history/-saved items created w/in the same day
        NSInteger selfOrderingIndex = [self dailySortPriority];
        NSInteger otherOrderingIndex = [contentGroup dailySortPriority];
        if (selfOrderingIndex > otherOrderingIndex) {
            return NSOrderedDescending;
        } else if (selfOrderingIndex < otherOrderingIndex) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    } else {
        // sort all items from different days and/or history/saved items by date, descending
        return -[self.date compare:contentGroup.date];
    }
}

@end

@interface WMFSiteContentGroup ()

@property (nonatomic, strong, readwrite) NSURL *siteURL;

@end

@implementation WMFSiteContentGroup

- (instancetype)initWithSiteURL:(NSURL *)url {
    return [self initWithDate:[NSDate date] siteURL:url];
}

- (instancetype)initWithDate:(NSDate *)date siteURL:(NSURL *)url {
    NSParameterAssert(date);
    self = [super initWithDate:date];
    if (self) {
        self.siteURL = url;
    }
    return self;
}
@end

@implementation WMFContinueReadingContentGroup

- (NSInteger)dailySortPriority {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 1;
    } else {
        return 0;
    }
}

@end

@implementation WMFMainPageContentGroup

- (NSInteger)dailySortPriority {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 0;
    } else {
        return 4;
    }
}

@end

@interface WMFRelatedPagesContentGroup ()

@property (nonatomic, strong, readwrite) NSURL *articleURL;

@end

@implementation WMFRelatedPagesContentGroup

- (instancetype)initWithArticleURL:(NSURL *)url date:(NSDate *)date {
    self = [super initWithDate:date siteURL:url.wmf_siteURL];
    if (self) {
        self.articleURL = url;
    }
    return self;
}

- (NSInteger)dailySortPriority {
    return 7;
}

@end

@interface WMFLocationContentGroup ()

@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, strong, readwrite) CLPlacemark *placemark;
@end

@implementation WMFLocationContentGroup

- (instancetype)initWithLocation:(CLLocation *)location placemark:(nullable CLPlacemark *)placemark siteURL:(NSURL *)url {
    self = [super initWithSiteURL:url];
    if (self) {
        self.location = location;
        self.placemark = placemark;
    }
    return self;
}

- (NSInteger)dailySortPriority {
    return 6;
}

@end

@implementation WMFPictureOfTheDayContentGroup

- (WMFContentType)contentType {
    return WMFContentTypeImage;
}

- (NSInteger)dailySortPriority {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 4;
    } else {
        return 3;
    }
}


@end

@implementation WMFRandomContentGroup

- (NSInteger)dailySortPriority {
    return 5;
}

@end

@implementation WMFFeaturedArticleContentGroup

- (NSInteger)dailySortPriority {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 2;
    } else {
        return 1;
    }
}

@end

@interface WMFTopReadContentGroup ()

@property (nonatomic, strong, readwrite) NSDate *mostReadDate;

@end
@implementation WMFTopReadContentGroup

- (WMFContentType)contentType {
    return WMFContentTypeTopReadPreview;
}

- (instancetype)initWithDate:(NSDate *)date mostReadDate:(NSDate *)mostReadDate siteURL:(NSURL *)url {
    NSParameterAssert(mostReadDate);
    self = [super initWithDate:date siteURL:url];
    if (self) {
        self.mostReadDate = mostReadDate;
    }
    return self;
}


- (NSInteger)dailySortPriority {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 3;
    } else {
        return 2;
    }
}

@end

@implementation WMFNewsContentGroup

- (WMFContentType)contentType {
    return WMFContentTypeStory;
}

- (NSInteger)dailySortPriority {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 3;
    } else {
        return 2;
    }
}

@end

@interface WMFAnnouncementContentGroup ()

@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSDate *visibilityStartDate;
@property (nonatomic, strong, readwrite) NSDate *visibilityEndDate;
@property (nonatomic, assign, readwrite) BOOL isVisible;

@end
@implementation WMFAnnouncementContentGroup

- (instancetype)initWithDate:(NSDate *)date visibilityStartDate:(NSDate *)start visibilityEndDate:(NSDate *)end siteURL:(NSURL *)url identifier:(NSString*)identifier{
    NSParameterAssert(start);
    NSParameterAssert(end);
    NSParameterAssert(identifier);
    self = [super initWithDate:date siteURL:url];
    if (self) {
        self.visibilityStartDate = start;
        self.visibilityEndDate = end;
        self.identifier = identifier;
    }
    return self;
}

- (BOOL)updateVisibilityBasedOnStartAndEndDates{
    NSDate* now = [NSDate date];
    if([now isLaterThanDate:self.visibilityStartDate] && [now isEarlierThanDate:self.visibilityEndDate]){
        if(!self.isVisible){
            self.isVisible = YES;
            return YES;
        }
    }else{
        if(self.isVisible){
            self.isVisible = NO;
            return YES;
        }
    }
    return NO;
}

- (WMFContentType)contentType {
    return WMFContentTypeAnnouncement;
}

@end

NS_ASSUME_NONNULL_END
